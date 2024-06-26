# frozen_string_literal: true

module SessionHelpers
  def log_in
    sign_in student
    visit root_path
    expect(page).to have_content("START A QUIZ")
  end

  def stub_omniauth # rubocop:disable Metrics/MethodLength
    OmniAuth.config.logger = Rails.logger
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:wonde] =
      # rubocop:disable Layout/LineLength
      OmniAuth::AuthHash.new(
        "provider" => "wonde",
        "uid" => nil,
        "info" => {},
        "credentials" =>
         {"token" =>
           "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjYyODRlNjc5NjdjZWJkMjc5YzE1MzIyMWY4MzYwYjJhMDkyYmVjMDBmYzM5OTE2MDY3ZjI5M2NhZjhjN2JkYjUwN2M0NTcyOTJmOGZkNWEzIn0.eyJhdWQiOiI2NzAxODUiLCJqdGkiOiI2Mjg0ZTY3OTY3Y2ViZDI3OWMxNTMyMjFmODM2MGIyYTA5MmJlYzAwZmMzOTkxNjA2N2YyOTNjYWY4YzdiZGI1MDdjNDU3MjkyZjhmZDVhMyIsImlhdCI6MTU0NDk1MDk3MCwibmJmIjoxNTQ0OTUwOTcwLCJleHAiOjE1NDYxNjA1NzAsInN1YiI6IjE4ODQ0Iiwic2NvcGVzIjpbXX0.i0--LjjetHyvxGfTU1nHliJwhhOWVvz0Mwj6xCQ1zeEVab9_GJkBDkY8rzautCfoF3Phwy8T36h2VBiTe38limO_anJCFOPlGYt5ajtMxdWRyQP3h5_zABzWfD7uLZGlyO6uM5BjbZG_BCKYeaQsg1ARuMx0nCcZhgiFJwa3x3NAdxLAfSoEMIGAQGxsy84JyRZW5d8exNvkM34OVgYmrc5bvYqiLYJeF9kNTBHqu9-flgx5LhmaInjJndR4U34UfmDqa308uzejelfuPHp7V2ZR6jW1iZ8kyN9pnZOXzDTLuTvV07ld3q00rQYZXpD76c0CUEouOXOUmtYVh1Z7GIAXfY6mVa6PDJUCkPH_OdkK9faz8NGx5bhHlf6rut5rp3uXDxhDxb6PpxjH935NCY2lwgsyaEmvJPGt8aU2_znBOd97fYmJ7rf6-7F79lAPG_PONLIvE4p6WCAtLZXpHaRCt_2F1yWZIchXMUIPbZi5HJp-YWZ0cjtn2FtpiDPEe0jgTvOWDK8C_rgXhjH4M3c1GR5I3kUc5oM4lZdz1l_2iHh7pmBjxqnWxmxNXtdMEK6ZCmIQgSQ-QmX6KmvJGkTgvosXN9dZimQqBf3pcplYi2jURwl288oJp5yLe_VavuK__Ey1Ta6QOaFZOzq0GZ4d3bL1KE9Xtm6F-NK_VLE",
          "refresh_token" => "def502008f248fc2adf1a1c05b69017ef567fe0a7f5977afd7f7f58263f1f5f6407bbbbbbb4c6168e83590ff7f358f634838e95ba000f97d7b5636aaace5c1d398a699011782a73d92453a1e8219dbc0b51bb3dd1ad454ac0f6a368f7f50c86a6cac23e40b37078e0d9616d2b32f169f6335ac6e9edcbfca12d19f2ccf79028125adee97110dfc0ab188ff201f53573b75c1191c348f9d5eae4b7084d04893f8f513663c82dfdac65aef30641e55a5ef30e98ed52d18f5c6bd00e8b32dd13d9b8eb47fff9194e4370cfbf7e58f2cc4ad063497c5576a8d160d07a69b3b5588989333e4b0d6cad4840ffbbde79bca4cab067712816f6dde36b8673c0c230f11936026bf8157655b890c6972cb46bfe098c5ab67bea4574b598c32b114e1b1aff6bad69bcd65775b57fce359af17fee8de32349f425459d89e8ebb0289f51c5b3bf17bfbc66488e61bce21b749e075349eb3aabfc554a5c7c5f3053a3dff8e511677244b5c045666bf24e9",
          "expires_at" => 1_546_160_571,
          "expires" => true},
        "extra" => {}
      )
    # rubocop:enable Layout/LineLength
  end

  def stub_google_omniauth
    # first, set OmniAuth to run in test mode
    OmniAuth.config.test_mode = true
    # then, provide a set of fake oauth data that
    # omniauth will use when a user tries to authenticate:
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      "provider" => "google_oauth2",
      "uid" => "123456123456",
      "info" =>
         {"name" => "Test",
          "email" => "test@test.com",
          "unverified_email" => "test@test.com",
          "email_verified" => true,
          "first_name" => "Test",
          "last_name" => "Person"}
    )
  end

  def setup_subject_database
    create(:enrollment, classroom: classroom, user: student)
    create(:multiplier)
  end

  def navigate_to_quiz
    visit(new_quiz_path(subject: subject.name))
    select Topic.last.name, from: "quiz_topic_id"
    click_button("Create Quiz")
  end

  def navigate_to_lucky_dip
    visit(new_quiz_path(subject: subject.name))
    select "Lucky Dip", from: "quiz_topic_id"
    click_button("Create Quiz")
  end

  def create_homework
    find("input#homework_due_date").click
    find(flatpickr_one_week_from_now).click
    select "70", from: "Required %"
    select topic.name, from: "Topic"
  end

  def create_homework_for_lesson
    find("input#homework_due_date").click
    find(flatpickr_one_week_from_now).click
    select "70", from: "Required %"
    select topic.name, from: "Topic"
    select lesson.title, from: "Lesson"
  end

  def initialize_name(user)
    "#{user.forename} #{user.surname[0]}"
  end

  def log_in_through_front_page(username, password)
    visit(root_path)
    click_button "Login"
    fill_in("user_login", with: username)
    fill_in("user_password", with: password)
    click_button "loginModal"
    find(".alert", text: "Signed in successfully")
  end

  def update_password(new_password)
    find_by_id("user_password").set(new_password)
    click_button("Update Password")
    find(".alert")
  end

  def create_file_blob(filename:, content_type:, metadata: nil)
    ActiveStorage::Blob.create_after_upload! io: file_fixture(filename).open, filename: filename,
      content_type: content_type, metadata: metadata
  end
end
