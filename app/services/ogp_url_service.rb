class OgpUrlService
  def self.default_fallback_url(request)
    Rails.logger.info "=== OgpUrlService.default_fallback_url start ==="

    begin
      helpers = ActionController::Base.helpers

      url = helpers.image_url("ogp.png", host: request.base_url)

      url = url.sub(%r{^http://}, "https://") if Rails.env.production?

      Rails.logger.info "OgpUrlService result: #{url}"
      url
    rescue => e
      Rails.logger.error "OgpUrlService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      fallback_url = "#{request.base_url}/assets/ogp.png"
      Rails.logger.info "OgpUrlService fallback: #{fallback_url}"
      fallback_url
    end
  end
end

