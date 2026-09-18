# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe User do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of :upi }
    it { is_expected.to validate_presence_of :role }
  end

  describe "accounts from Wonde" do
    include_context "with api_data"

    before do
      school_api_data
    end

    context "with student API data" do
      it "does not allow students missing a upi" do
        expect { create(:student, upi: "") }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "with students listed" do
        before { classroom_api_data["students"] = user_api_data }

        it "creates the students" do
          described_class.students_from_wonde(school_api_data, classroom_api_data)
          expect(described_class.find_by!(role: "student").forename).to eq(user_api_data["data"][0]["forename"])
        end

        it "returns the ids of the users it saves" do
          expect(described_class.students_from_wonde(school_api_data, classroom_api_data))
            .to contain_exactly(described_class.find_by!(role: "student").id)
        end
      end

      describe "generated usernames" do
        let(:usernames) { described_class.where(role: "student").pluck(:username) }

        def wonde_students(*names)
          data = names.map do |forename, surname|
            {"id" => SecureRandom.hex, "upi" => SecureRandom.hex, "forename" => forename, "surname" => surname}
          end
          {"data" => data}
        end

        before { classroom_api_data["students"] = students }

        context "with a single-word name" do
          let(:students) { wonde_students(%w[Leo Ward]) }

          it "joins the initial, surname and four digits" do
            described_class.students_from_wonde(school_api_data, classroom_api_data)
            expect(usernames).to contain_exactly(match(/\Alward\d{4}\z/))
          end
        end

        context "with a space in the surname" do
          let(:students) { wonde_students(["Jan", "Van Der Berg"]) }

          it "drops the spaces" do
            described_class.students_from_wonde(school_api_data, classroom_api_data)
            expect(usernames).to contain_exactly(match(/\Ajvanderberg\d{4}\z/))
          end
        end

        context "with punctuation and accents in the name" do
          let(:students) { wonde_students(["Émile", "O'Brien-Núñez"]) }

          it "keeps only plain letters" do
            described_class.students_from_wonde(school_api_data, classroom_api_data)
            expect(usernames).to contain_exactly(match(/\Aeobriennunez\d{4}\z/))
          end
        end

        context "with no Latin letters in the name" do
          let(:students) { wonde_students(%w[Дмитрий Иванов]) }

          it "falls back to a fixed stem" do
            described_class.students_from_wonde(school_api_data, classroom_api_data)
            expect(usernames).to contain_exactly(match(/\Auser\d{4}\z/))
          end
        end

        context "when the drawn digits are already taken" do
          let(:students) { wonde_students(%w[Leo Ward], %w[Lily Ward]) }

          before do
            allow(SecureRandom).to receive(:random_number).and_call_original
            allow(SecureRandom).to receive(:random_number).with(10_000).and_return(42, 42, 7)
          end

          it "draws again" do
            described_class.students_from_wonde(school_api_data, classroom_api_data)
            expect(usernames).to contain_exactly("lward0042", "lward0007")
          end
        end

        context "when every draw is taken" do
          let(:students) { wonde_students(%w[Leo Ward], %w[Lily Ward]) }

          before do
            allow(SecureRandom).to receive(:random_number).and_call_original
            allow(SecureRandom).to receive(:random_number).with(10_000).and_return(42)
          end

          it "raises rather than drawing forever" do
            expect { described_class.students_from_wonde(school_api_data, classroom_api_data) }
              .to raise_error(RuntimeError, /No free username/)
          end
        end
      end

      context "with employees listed" do
        before do
          classroom_api_data["employees"] = user_api_data
        end

        it "creates the employees" do
          described_class.employees_from_wonde(school_api_data, classroom_api_data)
          expect(described_class.find_by!(role: "employee").forename).to eq(user_api_data["data"][0]["forename"])
        end
      end

      context "when both employees and students are present" do
        before do
          classroom_api_data["students"] = user_api_data
          classroom_api_data["employees"] = alt_user_api_data
        end

        it "creates accounts for both employees and students" do
          described_class.students_from_wonde(school_api_data, classroom_api_data)
          described_class.employees_from_wonde(school_api_data, classroom_api_data)
          expect(described_class.count).to eq(2)
        end
      end

      context "when a user record already exists" do
        let(:existing_upi) { user_api_data["data"].first["upi"] }

        before do
          described_class.create!(
            upi: existing_upi,
            username: "test",
            provider: "Wonde",
            role: "employee",
            school: school_api_data
          )
          classroom_api_data["employees"] = user_api_data
        end

        it "preserves the existing username" do
          described_class.employees_from_wonde(school_api_data, classroom_api_data)
          expect(described_class.find_by!(upi: existing_upi).username).to eq("test")
        end
      end
    end
  end

  describe "#active_for_authentication?" do
    let(:user) { build_stubbed(:student, school: school, disabled: disabled) }
    let(:school) { build_stubbed(:school, sync_status: :successful) }
    let(:disabled) { false }

    it "is true for an enabled user" do
      expect(user).to be_active_for_authentication
    end

    context "when disabled after the school's sync has finished" do
      let(:disabled) { true }

      it "is false" do
        expect(user).not_to be_active_for_authentication
      end
    end

    context "when disabled while the school is syncing" do
      let(:disabled) { true }
      let(:school) { build_stubbed(:school, sync_status: :syncing) }

      it "is still false" do
        expect(user).not_to be_active_for_authentication
      end
    end
  end

  describe "#inactive_message" do
    it "names the disabled state" do
      expect(build_stubbed(:student, disabled: true).inactive_message).to eq(:disabled)
    end
  end
end
