# frozen_string_literal: true

require "omniauth-oauth2"
require "net/http"

module OmniAuth::Strategies
  class Wonde < OmniAuth::Strategies::OAuth2
    # Give your strategy a name.
    option :name, "wonde"

    GRAPHQL_URI = "https://api.wonde.com/graphql/me"

    # This is where you pass the options you would pass when
    # initializing your consumer from the OAuth gem.
    option :client_options,
      site: "https://api.wonde.com/graphql/me",
      authorize_url: "https://edu.wonde.com/oauth/authorize",
      token_url: "https://api.wonde.com/oauth/token"
  end
end
