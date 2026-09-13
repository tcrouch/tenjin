# frozen_string_literal: true

module CustomisationHelper
  def customisation_cost(style, bought_customisations)
    return if bought_customisations.include? style.id

    safe_join([
      content_tag(:i, nil, aria: {hidden: true}, class: "fas fa-star text-warning"),
      content_tag(:span, "Cost: ", class: "visually-hidden"),
      style.cost.to_s
    ])
  end
end
