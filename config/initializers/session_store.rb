# frozen_string_literal: true

# Use secure, lax SameSite cookies in production to keep OmniAuth state
Rails.application.config.session_store :cookie_store,
  key: "_omoide_gift_session",
  secure: Rails.env.production?,
  same_site: (Rails.env.production? ? :none : :lax)
