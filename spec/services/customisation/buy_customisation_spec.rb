require 'rails_helper'

RSpec.describe Customisation::BuyCustomisation do
  include_context 'default_creates'

  let(:customisation) { create(:customisation, cost: 5, customisation_type: 0) }
  let(:old_customisation) { create(:customisation, cost: 2, customisation_type: 0) }
  let(:old_customisation_unlock) do
    create(:customisation_unlock, customisation: old_customisation, user: student, active: false)
  end

  before do
    student.update_attribute(:challenge_points, 10)
    create(:customisation_unlock, customisation: old_customisation, user: student, active: true)
  end

  context 'when buying a new dashboard style' do
    it 'creates the correct customisation unlock' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
    end

    it 'sets the new customisation unlock to active' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: customisation).first.active).to eq(true)
    end

    it 'sets the old customisation unlock to inactive' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: old_customisation).first.active).to eq(false)
    end

    it 'deducts the correct amount of challenge points' do
      described_class.new(student, customisation).call
      expect(student.challenge_points).to eq(5)
    end
  end

  context 'when moving from the default customisation' do
    before do
      CustomisationUnlock.all.destroy_all
    end

    it 'handles not having an existing customisation unlock' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
    end
  end

  context 'when buying something I do not have points for' do
    before do
      student.update_attribute(:challenge_points, 3)
    end

    it 'alerts me that I do not have enough points' do
      expect(described_class.new(student, customisation).call.errors).to eq('You do not have enough points')
    end
  end

  context 'when buying something I have already bought' do
    before do
      create(:customisation_unlock, customisation: customisation, user: student, active: false)
    end

    it 'does not cost anything' do
      described_class.new(student, customisation).call
      expect { student.reload }.to change(student, :challenge_points).by(0)
    end

    it 'sets the new customisation unlock to active' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: customisation).first.active).to eq(true)
    end

    it 'sets the old customisation unlock to inactive' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: old_customisation).first.active).to eq(false)
    end
  end
end
