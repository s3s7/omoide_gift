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
    image = options[:image].presence || image_url("ogp.png")
    configs = {
      separator: "|",
      reverse: true,
      site:,
      title:,
      description:,
      keywords:,
      canonical: request.original_url,
      icon: {
        href: image_url("ogp.png")
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

  # zdef default_meta_tags
  #   {
  #     site: "Live Fes",
  #     title: "音楽ライブ・フェスの余韻を共有できるサービス",
  #     reverse: true,
  #     charset: "utf-8",
  #     description: "Live Fesでは、音楽ライブやフェスの余韻や喪失感を参加者同士で共通し、感想や思い出を語り合うことができます。",
  #     keywords: "音楽,ライブ,フェス,余韻,喪失感,共有",
  #     canonical: request.original_url,
  #     separator: "|",
  #     og: {
  #       site_name: :site,
  #       title: :title,
  #       description: :description,
  #       type: "website",
  #       url: request.original_url,
  #       image: image_url("ogp.png"),
  #       local: "ja-JP"
  #     },
  #     twitter: {
  #       card: "summary_large_image",
  #       image: image_url("ogp.png")
  #     }
  #   }
  # end
end
