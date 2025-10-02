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
    return nil unless avatar&.attached? && record.respond_to?(:persisted?) && record.persisted?

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
    rescue ActiveRecord::RecordNotFound, NoMethodError => e
      Rails.logger.warn "Avatar variant generation failed: #{e.message}"
      nil
    end
  end

  # OGP設定
  def default_meta_tags
    {
      site: "思い出ギフト",
      title: "思い出ギフトー大切な人との思い出を記録し、共有するアプリ",
      reverse: true,
      charset: "utf-8",
      description: "思い出ギフトはギフトの記録などできます",
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
end
