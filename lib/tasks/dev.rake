if Rails.env.development? || Rails.env.test?
  require "factory_bot"

  namespace :dev do
    desc "Sample data for local development environment"
    task prime: "db:setup" do
      include FactoryBot::Syntax::Methods

      Admin.create(
        email: `git config user.email`,
        password: "password",
        password_confirmation: "password",
        role: "super"
      )
    end
  end
end
