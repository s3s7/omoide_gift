class Rack::Attack
  # Deviseの通常ログインを過剰リトライから守る
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end
end
