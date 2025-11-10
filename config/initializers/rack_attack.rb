class Rack::Attack
  # Deviseの通常ログインを過剰リトライから守る
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # LINE ログインのコールバックは常に許可（部分的セーフリスト）
  # OmniAuth 2系はPOSTコールバックの可能性があるため、GET/POST両方を許可
  # CALLBACK_PATHS = %w[/users/auth/line/callback /auth/line/callback].freeze
  # safelist("allow LINE callback") do |req|
  #   CALLBACK_PATHS.include?(req.path) && %w[GET POST].include?(req.request_method)
  # end
end
