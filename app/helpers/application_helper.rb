module ApplicationHelper
  def show_meta_tags
    assign_meta_tags if display_meta_tags.blank?
    display_meta_tags
  end

  def assign_meta_tags(options = {})
    defaults = t("meta_tags.defaults")
    options.reverse_merge!(defaults)
    site = options[:site]
    title = options[:title]
    description = options[:description]
    keywords = options[:keywords]
    # Fallback image must exist and be absolute. Use the base OGP image.
    image = options[:image].presence || image_url("default_gift.webp")
    configs = {
      separator: "|",
      reverse: true,
      site:,
      title:,
      description:,
      keywords:,
      canonical: request.original_url,
      icon: {
        href: image_url("default_gift.webp")
      },
      og: {
        type: "website",
        title: title.presence || site,
        description:,
        url: request.original_url,
        image:,
        site_name: site
      },
      twitter: {
        site:,
        card: "summary_large_image",
        image:
      }
    }
    set_meta_tags(configs)
  end

  # 汎用アバター表示ヘルパー
  def display_avatar(record, size = :medium)
    return nil unless record&.respond_to?(:avatar)
    avatar = record.avatar
    return nil unless avatar&.attached? && avatar&.blob&.persisted? && record.respond_to?(:persisted?) && record.persisted?

    begin
      case size
      when :small
        avatar.variant(resize_to_fill: [ 40, 40 ])
      when :medium
        avatar.variant(resize_to_fill: [ 80, 80 ])
      when :large
        avatar.variant(resize_to_fill: [ 160, 160 ])
      else
        avatar
      end
    rescue ActiveRecord::RecordNotFound, NoMethodError, ArgumentError => e
      Rails.logger.warn "Avatar variant generation failed: #{e.message}"
      nil
    end
  end

  # OGP設定
  def default_meta_tags
    {
      site: "めぐりギフト",
      title: "めぐりギフトー大切な人との思い出を記録し、共有するアプリ",
      reverse: true,
      charset: "utf-8",
      description: "めぐりギフトはギフトの記録などできます",
      keywords: "ギフト、記録、共有",
      canonical: request.original_url,
      separator: "|",
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: "website",
        url: request.original_url,
        image: image_url("default_gift.webp"),
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@",
        image: image_url("default_gift.webp")
      }
    }
  end

  # === ギフト方向（贈った/もらった）表示ユーティリティ ===
  # 引数には GiftRecord あるいはシンボル/文字列(:given/:received/"given"/"received") を受け取る
  def gift_direction_color(record_or_value)
    dir = extract_gift_direction(record_or_value)
    case dir
    when :received then "#FF6B6B"
    when :given    then "#28a745"
    else "#6c757d"
    end
  end

  def gift_direction_icon_class(record_or_value)
    dir = extract_gift_direction(record_or_value)
    case dir
    when :received then "fas fa-hand-holding-heart"
    when :given    then "fas fa-gift"
    else "fas fa-question-circle"
    end
  end

  def gift_direction_display_text(record_or_value)
    dir = extract_gift_direction(record_or_value)
    case dir
    when :received then "もらったギフト"
    when :given    then "贈ったギフト"
    else "未設定"
    end
  end

  def gift_direction_description_text(record_or_value)
    dir = extract_gift_direction(record_or_value)
    case dir
    when :received then "あなたが受け取ったギフトを記録します"
    when :given    then "あなたが贈ったギフトを記録します"
    else "ギフトの種別を選択してください"
    end
  end

  # ビュー補助: 現在の方向値を 'given' / 'received' の文字列で返す
  def gift_direction_value(record_or_value)
    dir = extract_gift_direction(record_or_value)
    dir ? dir.to_s : ""
  end

  # ビュー補助: トグルのchecked判定（targetに :received などを渡す）
  def default_gift_direction_checked?(record_or_value, target)
    extract_gift_direction(record_or_value) == extract_gift_direction(target)
  end

  private

  # :given/:received を抽出
  def extract_gift_direction(record_or_value)
    value = if record_or_value.respond_to?(:gift_direction)
              record_or_value.gift_direction
    else
              record_or_value
    end

    case value
    when :given, "given", 0 then :given
    when :received, "received", 1 then :received
    else nil
    end
  end
end
