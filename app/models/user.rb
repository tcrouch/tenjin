# frozen_string_literal: true

# A pupil or member of staff at a school, synced from Wonde and signed in through Devise
class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # Note - removed :registerable so new accounts cannot be created
  devise :database_authenticatable, :rememberable, :trackable, :recoverable,
    :omniauthable, omniauth_providers: %i[wonde google_oauth2], authentication_keys: [:login]

  has_many :all_time_topic_scores
  has_many :challenge_progresses
  has_many :enrollments
  has_many :homework_progresses
  has_many :quizzes
  has_many :topic_scores

  has_many :classrooms, through: :enrollments
  has_many :homeworks, through: :classrooms
  has_many :subjects, through: :classrooms

  belongs_to :school

  enum :role, {student: 0, employee: 1, contact: 2, school_admin: 3}
  validates :upi, presence: true
  validates :role, presence: true

  QUIZ_COOLDOWN_PERIOD = 40

  def full_name = "#{forename} #{surname}"

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  # Needed to allow users to sign in with either a username or an email
  attr_writer :login

  def login
    @login || username || email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = devise_parameter_filter.filter(warden_conditions)
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value",
        {value: login.downcase}]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  # A finished sync lists everyone still at the school; anyone it dropped loses access
  def active_for_authentication?
    super && !disabled?
  end

  def inactive_message
    disabled? ? :disabled : super
  end

  def self.from_omniauth(auth, current_user = nil)
    # Wonde users are stored with capitalized provider; the OmniAuth strategy returns "wonde"
    provider = (auth.provider == "wonde") ? "Wonde" : auth.provider
    user = find_by(provider: provider, upi: auth.info&.upi)
    user = find_by(oauth_provider: auth.provider, oauth_uid: auth.uid) if user.nil?

    return user if user.present?

    # If signed in and its an oauth2 google request, assume linking of accounts
    return unless auth.provider == "google_oauth2" && current_user.present?

    save_oauth_user_details(auth, current_user)
  end

  def self.save_oauth_user_details(auth, current_user)
    return if auth.info.blank?

    current_user.oauth_uid = auth.uid
    current_user.oauth_provider = auth.provider
    current_user.oauth_email = auth.info.email
    current_user.save!
    current_user
  end

  def unlink_account
    self.oauth_uid = ""
    self.oauth_provider = ""
    save
  end

  # Returns the ids of every user the class lists, so the sync can tell who has left
  def self.from_wonde(school, wonde_class, classroom)
    ids = create_employee_users(wonde_class, school)
    return ids if classroom.subject.blank?

    ids + create_student_users(wonde_class, school)
  end

  def seconds_left_on_cooldown
    return -1 if time_of_last_quiz.nil?

    (QUIZ_COOLDOWN_PERIOD - (Time.current - Time.zone.parse(time_of_last_quiz.to_s))).round
  end

  class << self
    private

    def create_student_users(wonde_class, school)
      create_users(wonde_class, "students", :student, school)
    end

    def create_employee_users(wonde_class, school)
      create_users(wonde_class, "employees", :employee, school)
    end

    def create_users(wonde_class, collection, role, school)
      # A class Wonde maps to no subject carries nobody this app has a use for
      return [] if wonde_class["subject"].blank?

      people = wonde_class.dig(collection, "data")
      return [] if people.blank?

      people.filter_map do |person|
        u = initialize_user(person, role, school)
        u.id if u.save # invalid records are silently skipped
      end
    end

    # Random digits: none to misread or blur into the surname, and a class list doesn't reveal usernames
    def generate_username(user)
      stem = "#{username_letters(user.forename)[0]}#{username_letters(user.surname)}".presence || "user"
      100.times do
        username = format("%s%04d", stem, SecureRandom.random_number(10_000))
        return username unless User.exists?(username: username)
      end
      raise "No free username after 100 draws"
    end

    def username_letters(name)
      I18n.transliterate(name.to_s).downcase.gsub(/[^a-z]/, "")
    end

    def initialize_user(user, role, school)
      u = User.where(provider: "Wonde", upi: user["upi"]).first_or_initialize
      u.attributes = {school_id: school.id, role: role, provider: "Wonde",
                       upi: user["upi"], forename: user["forename"], surname: user["surname"], disabled: false}
      u.challenge_points = 0 if u.challenge_points.blank?
      u.username = generate_username(u) if u.new_record? || u.username.blank?
      u
    end
  end
end
