class ImagesController < ApplicationController
  MAX_TEXT_LENGTH = 50
  OGP_CACHE_TTL = 1.hour
  DEFAULT_OGP_PATH = Rails.root.join("app/assets/images/default_ogp.webp")
  FALLBACK_OGP_PATH = Rails.root.join("app/assets/images/ogp.webp")

  skip_before_action :require_login, raise: false
  # skip_before_action :verify_supported_browser

  # 同じテキストに対する連続リクエストを防ぐ
  before_action :set_cors_headers

  def ogp
    text = sanitize_text(ogp_params[:text])

    # ETagを使った条件付きレスポンス（stale? を利用）
    etag = generate_etag(text)
    if stale?(etag: etag, public: true)
      # 画像生成とレスポンス
      render_ogp_image(text, etag)
    end
  end

  private

  def ogp_params
    params.permit(:text)
  end

  def sanitize_text(text)
    # テキストのサニタイズと長さ制限
    return "ギフト記録" if text.blank?

    # 改行や特殊文字を除去、長さを制限
    sanitized = text.to_s.gsub(/[\r\n\t]/, " ").strip
    sanitized.length > MAX_TEXT_LENGTH ? sanitized[0...MAX_TEXT_LENGTH] + "..." : sanitized
  end

  def generate_etag(text)
    Digest::MD5.hexdigest("ogp_#{text}_v1")
  end

  def render_ogp_image(text, etag)
    cache_key = "ogp_image_#{etag}"

    image_data = Rails.cache.fetch(cache_key, expires_in: OGP_CACHE_TTL) do
      generate_ogp_image(text)
    end

    if image_data
      response.headers["Cache-Control"] = "public, max-age=3600"
      response.headers["ETag"] = etag

      send_data image_data, type: "image/webp", disposition: "inline"
    else
      send_default_ogp_image
    end
  rescue => e
    Rails.logger.error "OGP画像レンダリングエラー: #{e.message}"
    send_default_ogp_image
  end

  def generate_ogp_image(text)
    OgpCreator.build(text).to_blob
  rescue => e
    Rails.logger.error "OgpCreator実行エラー: #{e.message}"
    nil
  end

  def send_default_ogp_image
    # Prefer explicit default, fallback to base OGP image
    if File.exist?(DEFAULT_OGP_PATH)
      send_file DEFAULT_OGP_PATH, type: "image/webp", disposition: "inline"
    elsif File.exist?(FALLBACK_OGP_PATH)
      send_file FALLBACK_OGP_PATH, type: "image/webp", disposition: "inline"
    else
      head :not_found
    end
  end

  def set_cors_headers
    # SNSのクローラーがアクセスできるように
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET"
  end
end
