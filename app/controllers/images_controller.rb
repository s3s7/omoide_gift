# class ImagesController < ApplicationController
#   skip_before_action :require_login, raise: false

#   def ogp
#     text = ogp_params[:text] || "ギフト記録"
#     image = OgpCreator.build(text)
#     send_data image.to_blob, type: "image/png", disposition: "inline"
#   end

#   private

#   def ogp_params
#     params.permit(:text)
#   end
# end
class ImagesController < ApplicationController
  skip_before_action :require_login, raise: false

  # 同じテキストに対する連続リクエストを防ぐ
  before_action :set_cors_headers

  def ogp
    text = sanitize_text(ogp_params[:text])

    # ETagを使った条件付きレスポンス
    etag = generate_etag(text)

    if request.fresh?(response)
      head :not_modified
      return
    end

    # 画像生成とレスポンス
    render_ogp_image(text, etag)
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
    sanitized.length > 50 ? sanitized[0..49] + "..." : sanitized
  end

  def generate_etag(text)
    Digest::MD5.hexdigest("ogp_#{text}_v1")
  end

  def render_ogp_image(text, etag)
    cache_key = "ogp_image_#{etag}"

    image_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      generate_ogp_image(text)
    end

    if image_data
      response.headers["Cache-Control"] = "public, max-age=3600"
      response.headers["ETag"] = etag

      send_data image_data, type: "image/png", disposition: "inline"
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
    default_path = Rails.root.join("app/assets/images/default_ogp.png")
    fallback_path = Rails.root.join("app/assets/images/ogp.png")

    if File.exist?(default_path)
      send_file default_path, type: "image/png", disposition: "inline"
    elsif File.exist?(fallback_path)
      send_file fallback_path, type: "image/png", disposition: "inline"
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
