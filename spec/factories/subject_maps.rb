FactoryBot.define do
  factory :subject_map do
    client_id { 'subject1' }
    client_subject_name { 'Computer Science' }
    association :subject, factory: :subject
  end
end