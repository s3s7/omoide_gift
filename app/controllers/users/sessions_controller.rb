# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def new
      # Warm the session so the cookie exists before OmniAuth redirect
      session[:session_warmed_at] ||= Time.current.to_i
      super
    end
  end
end
