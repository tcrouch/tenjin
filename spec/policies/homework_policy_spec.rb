# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeworkPolicy, :default_creates do
  subject(:policy) { described_class.new(actor, build_stubbed(:homework, classroom: classroom)) }

  describe "#show?" do
    context "as a teacher" do
      let(:actor) { teacher }
      it { is_expected.to be_show }
    end

    context "as a teacher of another school" do
      let(:actor) { build_stubbed(:teacher, school: build_stubbed(:school)) }
      it { is_expected.not_to be_show }
    end

    context "as a student of the school" do
      let(:actor) { student }
      it { is_expected.not_to be_show }
    end
  end
end
