class OgpCreator
  require "mini_magick"

  BASE_IMAGE_PATH = Rails.root.join("app", "assets", "images", "ogp.webp").to_s
  GRAVITY = "center"
  FONT = Rails.root.join("app", "assets", "fonts", "UtsukushiFONT.otf").to_s
  TITLE_FONT_SIZE = 160
  SUBTITLE_FONT_SIZE =  210
  SUBTITLE_CHARS_PER_LINE = 7
  SUBTITLE_ROW_LIMIT = 4
  PRIMARY_FILL_COLOR = "#F6B352"
  SECONDARY_FILL_COLOR = "#ffbdd3"
  STROKE_COLOR = "#ffffff"
  PRIMARY_DRAW_OFFSET = "0,-500"
  SECONDARY_DRAW_OFFSET = "0,40"

  def self.build(text)
    prepared_text = prepare_text(text)
    image = MiniMagick::Image.open(BASE_IMAGE_PATH)
    draw_primary_title(image)
    draw_secondary_title(image, prepared_text)
    image.format "webp"
    image
  end

  private

  def self.draw_primary_title(image)
    image.combine_options do |config|
      config.font FONT
      config.fill PRIMARY_FILL_COLOR
      config.stroke STROKE_COLOR
      config.strokewidth 4
      config.gravity GRAVITY
      config.pointsize TITLE_FONT_SIZE
      config.kerning 6
      config.interline_spacing -8
      config.draw "text #{PRIMARY_DRAW_OFFSET} 'おすすめギフト'"
    end
  end

  def self.draw_secondary_title(image, text)
    image.combine_options do |config|
      config.font FONT
      config.fill SECONDARY_FILL_COLOR
      config.stroke "none"
      config.gravity GRAVITY
      config.pointsize SUBTITLE_FONT_SIZE
      config.kerning 4
      config.interline_spacing -6
      config.draw "text #{SECONDARY_DRAW_OFFSET} '#{text}'"
    end
  end

  def self.prepare_text(text)
    sanitized = text.to_s.strip
    sanitized = "ギフト記録" if sanitized.blank?

    sanitized.each_char
             .each_slice(SUBTITLE_CHARS_PER_LINE)
             .map { |chars| chars.join }
             .first(SUBTITLE_ROW_LIMIT)
             .join("\n")
  end
end
