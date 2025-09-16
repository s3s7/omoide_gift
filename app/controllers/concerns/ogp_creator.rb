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
  BASE_IMAGE_PATH = Rails.root.join("app", "assets", "images", "ogp.png").to_s
  GRAVITY = "center"
  TEXT_POSITION = "0,0"
  FONT = Rails.root.join("app", "assets", "fonts", "UtsukushiFONT.otf").to_s
  FONT_SIZE = 65
  INDENTION_COUNT = 16
  ROW_LIMIT = 8

  def self.build(text)
    text = prepare_text(text)
    image = MiniMagick::Image.open(BASE_IMAGE_PATH)
    image.combine_options do |config|
      config.font FONT
      config.fill "red"
      config.gravity GRAVITY
      config.pointsize FONT_SIZE
      config.draw "text #{TEXT_POSITION} '#{text}'"
    end
    image
  end

  private
  def self.prepare_text(text)
    text.to_s.scan(/.{1,#{INDENTION_COUNT}}/)[0...ROW_LIMIT].join("\n")
  end
end
