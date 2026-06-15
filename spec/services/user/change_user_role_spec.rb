# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::ChangeUserRole, :default_creates do
  let(:teacher) { create(:teacher, school: school) }

  describe "validation failures" do
    it "fails when user is nil" do
      result = described_class.call(user: nil, role: "school_admin", action: :add)
      expect(result).to be_failure
      expect(result.error).to eq "User not found"
    end

    it "fails when role is nil" do
      result = described_class.call(user: teacher, role: nil, action: :add)
      expect(result).to be_failure
      expect(result.error).to eq "Role not found"
    end

    it "fails when action is not :add or :remove" do
      result = described_class.call(user: teacher, role: "school_admin", action: :sideways)
      expect(result).to be_failure
      expect(result.error).to eq 'Action must be "add" or "remove"'
    end

    it "fails when subject is required but missing" do
      result = described_class.call(user: teacher, role: "question_author", action: :add)
      expect(result).to be_failure
      expect(result.error).to eq "Must include a subject with a lesson or question author role"
    end

    it "fails (rather than raising) when role is unrecognised" do
      result = described_class.call(user: teacher, role: "wizard", action: :add)
      expect(result).to be_failure
      expect(result.error).to match(/unrecognised role/i)
    end
  end

  describe "success paths" do
    it "adds the school_admin role" do
      result = described_class.call(user: teacher, role: "school_admin", action: :add)
      expect(result).to be_success
      expect(teacher.has_role?(:school_admin)).to be true
    end

    it "adds a question_author role scoped to a subject" do
      subject = create(:subject)
      result = described_class.call(user: teacher, role: "question_author", action: :add, subject: subject.id)
      expect(result).to be_success
      expect(teacher.has_role?(:question_author, subject)).to be true
    end

    it "removes a previously assigned role" do
      teacher.add_role(:school_admin)
      result = described_class.call(user: teacher, role: "school_admin", action: :remove)
      expect(result).to be_success
      expect(teacher.has_role?(:school_admin)).to be false
    end
  end
end
