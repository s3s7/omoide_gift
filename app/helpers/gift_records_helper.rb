module GiftRecordsHelper
  # 単一のActiveStorage添付画像をサイズ変換しつつ、安全に表示（失敗時はデフォルト画像）
  # 使用例:
  #   <%= gift_image_with_fallback(image, size: [300,300], alt: '説明', css_class: '...', loading: 'lazy') %>
  def gift_image_with_fallback(attachment, size:, alt:, css_class: "", loading: "lazy")
    begin
      if attachment&.blob&.persisted?
        image_tag attachment.variant(resize_to_fill: size),
                  class: css_class,
                  alt: alt,
                  loading: loading
      else
        image_tag "default_gift.webp",
                  class: css_class,
                  alt: alt,
                  loading: loading
      end
    rescue => e
      Rails.logger.warn "gift_image_with_fallback error: #{e.class} - #{e.message}"
      image_tag "default_gift.webp", class: css_class, alt: alt, loading: loading
    end
  end

  # ギフト記録のメイン画像を安全に表示（失敗/未設定時はデフォルト画像）
  def gift_main_image_with_fallback(record, size:, css_class: "", loading: "lazy")
    alt = "#{record.display_item_name}のギフト画像"
    gift_image_with_fallback(record&.main_image, size: size, alt: alt, css_class: css_class, loading: loading)
  end
end
