# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Employee views a user record", :default_creates, :js do
  let(:second_classroom) { create(:classroom, school: school) }
  let(:homework_different_class) { create(:homework, classroom: second_classroom, topic: topic) }
  let(:enrollment_different_class) { create(:enrollment, user: student, classroom: second_classroom) }

  context "when visiting a user record" do
    before do
      sign_in teacher
      create(:enrollment, user: student, classroom: classroom)
      create(:enrollment, user: teacher, classroom: classroom)
      homework
    end

    it "opens the student record webpage" do
      visit(user_path(student))
      expect(page).to have_current_path(user_path(student))
    end

    it "shows uncompleted homeworks" do
      visit(user_path(student))
      expect(page).to have_content(homework.topic.name).and have_css("svg.fa-times")
    end

    it "shows recently completed homeworks" do
      HomeworkProgress.all.update_all(completed: true)
      visit(user_path(student))
    end

    it "only shows the homeworks for the classes the teacher belongs to" do
      enrollment_different_class
      homework_different_class
      visit(user_path(student))
      expect(page).to have_no_css("tr[data-homework='#{homework_different_class.id}'")
    end

    context "when resetting passwords" do
      let(:different_employee) { create(:teacher, school: school) }
      let(:school_admin) { create(:school_admin, school: school) }

      before do
        sign_in teacher
      end

      it "lets me reset a student password" do
        visit(user_path(student))
        update_password(new_password)
        sign_out teacher
        log_in_through_front_page(student.username, new_password)
        expect(page).to have_content(student.forename).and have_content(student.surname)
      end

      it "does not allow me to reset an employee password" do
        visit(user_path(different_employee))
        expect(page).to have_no_css("#user_password")
      end

      it "does not allow me to reset a school admin password" do
        visit(user_path(school_admin))
        expect(page).to have_no_css("#user_password")
      end
    end
  end
end
