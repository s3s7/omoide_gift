# frozen_string_literal: true

if Rails.env.production?
  # Ensure OmniAuth generates callback URLs with the correct HTTPS host
  OmniAuth.config.full_host = "https://omoide-gift.onrender.com"
end
