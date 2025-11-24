class OgpUrlService
  def self.default_fallback_url(request)
    begin
      helpers = ActionController::Base.helpers

      url = helpers.image_url("ogp.webp", host: request.base_url)

      url = url.sub(%r{^http://}, "https://") if Rails.env.production?
      url
    rescue => e
      Rails.logger.error "OgpUrlService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      fallback_url = "#{request.base_url}/assets/ogp.webp"
      fallback_url
    end
  end
end
