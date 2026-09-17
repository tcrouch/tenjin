# frozen_string_literal: true

# Page furniture shared by the admin area's views
module AdminAreaHelper
  # Titles the tab and heads the page; breadcrumbs are [label, path] pairs leading to it, and the block yields its actions
  def admin_page_header(title, breadcrumbs: [], &actions)
    content_for(:title) { tag.title("#{title} · Tenjin admin") }
    render "system/page_header", title: title, breadcrumbs: breadcrumbs, actions: actions && capture(&actions)
  end
end
