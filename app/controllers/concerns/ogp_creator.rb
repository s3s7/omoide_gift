# class OgpCreator
#   require "mini_magick"

#   BASE_IMAGE_PATH = Rails.root.join("app", "assets", "images", "ogp.png")
#   CUSTOM_FONT_PATH = Rails.root.join("app", "assets", "fonts", "UtsukushiFONT.otf")
#   FONT_SIZE = 65
#   FONT_COLOR = "red"
#   MAX_TEXT_LENGTH = 128
#   INDENTION_COUNT = 16
#   ROW_LIMIT = 8

#   def self.build(text)
#     # 入力値の検証とサニタイゼーション
#     return create_error_image("テキストが無効です") if text.blank?
#     return create_error_image("テキストが長すぎます") if text.length > MAX_TEXT_LENGTH

#     begin
#       # ベース画像の存在確認
#       unless File.exist?(BASE_IMAGE_PATH)
#         Rails.logger.error "OGP base image not found: #{BASE_IMAGE_PATH}"
#         return create_error_image("画像が見つかりません")
#       end

#       text = prepare_text(text)
#       image = MiniMagick::Image.open(BASE_IMAGE_PATH)

#       # テキストを画像に描画
#       image.combine_options do |c|
#         c.gravity "center"
#         c.pointsize FONT_SIZE
#         c.fill FONT_COLOR
#         # カスタムフォントを使用
#         c.font CUSTOM_FONT_PATH.to_s if File.exist?(CUSTOM_FONT_PATH)
#         # テキストを安全にエスケープ
#         safe_text = escape_text_for_imagemagick(text)
#         c.draw "text 0,0 \"#{safe_text}\""
#       end

#       image
#     rescue MiniMagick::Error => e
#       Rails.logger.error "MiniMagick error: #{e.message}"
#       create_error_image("画像生成エラー")
#     rescue StandardError => e
#       Rails.logger.error "OGP generation error: #{e.message}"
#       create_error_image("予期しないエラー")
#     end
#   end

#   private

#   def self.prepare_text(text)
#     # 改行を正規化し、文字数制限を適用
#     normalized_text = text.to_s.gsub(/\r\n|\r/, "\n").strip

#     # 16文字ずつで改行し、最大8行まで
#     lines = []
#     normalized_text.each_line do |line|
#       line.strip!
#       while line.length > INDENTION_COUNT && lines.length < ROW_LIMIT
#         lines << line[0, INDENTION_COUNT]
#         line = line[INDENTION_COUNT..-1]
#       end
#       if line.length > 0 && lines.length < ROW_LIMIT
#         lines << line
#       end
#       break if lines.length >= ROW_LIMIT
#     end

#     lines.join("\n")
#   end


#   def self.escape_text_for_imagemagick(text)
#     # ImageMagickのdrawコマンド用に特殊文字をエスケープ
#     text.gsub('\\', '\\\\')
#         .gsub('"', '\\"')
#         .gsub("'", "\\'")
#         .gsub("\n", "\\n")
#   end

#   def self.create_error_image(error_message = "エラー")
#     # エラー時の代替画像を生成
#     begin
#       if File.exist?(BASE_IMAGE_PATH)
#         # ベース画像があればそれを使用してエラーメッセージを描画
#         image = MiniMagick::Image.open(BASE_IMAGE_PATH)
#         image.combine_options do |c|
#           c.gravity "center"
#           c.pointsize 48
#           c.fill "black"
#           c.font CUSTOM_FONT_PATH.to_s if File.exist?(CUSTOM_FONT_PATH)
#           c.draw "text 0,0 \"#{escape_text_for_imagemagick(error_message)}\""
#         end
#         image
#       else
#         # ベース画像がない場合は新規作成
#         create_blank_image_with_text(error_message)
#       end
#     rescue StandardError => e
#       Rails.logger.error "Error creating error image: #{e.message}"
#       # 最終的なフォールバック: 最もシンプルな画像作成
#       create_minimal_fallback_image
#     end
#   end

#   def self.create_blank_image_with_text(text)
#     # Canvas画像を作成してテキストを描画
#     image = MiniMagick::Image.read(create_canvas_blob)

#     image.combine_options do |c|
#       c.gravity "center"
#       c.pointsize 48
#       c.fill "black"
#       c.font CUSTOM_FONT_PATH.to_s if File.exist?(CUSTOM_FONT_PATH)
#       c.draw "text 0,0 \"#{escape_text_for_imagemagick(text)}\""
#     end

#     image
#   end

#   def self.create_minimal_fallback_image
#     # 最も基本的な空白画像を作成
#     MiniMagick::Image.read(create_canvas_blob)
#   end

#   def self.create_canvas_blob
#     # canvas:を使用して空白画像を作成
#     image = MiniMagick::Image.read("canvas:#f0f0f0")
#     image.resize "1200x630"
#     image.format "png"
#     image.to_blob
#   end
# end
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
