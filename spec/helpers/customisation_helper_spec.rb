# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomisationHelper do
  describe "#customisation_cost" do
    let(:style) { build_stubbed(:customisation, cost: 25) }

    it "returns nothing for a bought customisation" do
      expect(helper.customisation_cost(style, [style.id])).to be_nil
    end

    it "renders a warning-coloured star before the cost" do
      html = helper.customisation_cost(style, [])

      expect(html).to eq('<i aria-hidden="true" class="fas fa-star text-warning"></i>25')
    end
  end
end
