class ConvertGiftImagesToWebpJob < ApplicationJob
  queue_as :default

  # ギフト記録の画像をWebPへ変換し、元の添付を置き換える
  # - MiniMagick(ImageMagick) 前提
  # - 順序保持のため、Attachment自体は残し、blobのみ差し替える
  def perform(gift_record_id)
    record = GiftRecord.find_by(id: gift_record_id)
    return unless record.present?
    return unless record.images.attached?

    record.images.attachments.each do |attachment|
      convert_attachment_to_webp!(attachment)
    end
  rescue => e
    Rails.logger.error "[ConvertGiftImagesToWebpJob] Error: #{e.class} - #{e.message}"
  end

  private

  def convert_attachment_to_webp!(attachment)
    blob = attachment.blob
    return unless blob.present?

    # 画像以外、またはすでにWebPはスキップ
    return unless blob.content_type.to_s.start_with?("image/")
    return if blob.content_type.to_s == "image/webp" || attachment.filename.to_s.downcase.end_with?(".webp")

    original_blob = blob

    # ダウンロードしてWebPへ変換
    blob.open do |file|
      require "mini_magick"

      image = MiniMagick::Image.open(file.path)
      image.auto_orient # EXIFの向きを正す
      image.strip       # 余分なメタデータを削除

      # 出力先一時ファイル
      tmp_out = Tempfile.new([ "gift_record_#{attachment.id}", ".webp" ])
      tmp_out.binmode

      begin
        # 品質は適宜調整（80〜90程度が実用的）
        image.format("webp") do |c|
          c.quality "85"
        end
        image.write(tmp_out.path)

        new_filename = build_webp_filename(attachment.filename.to_s)
        new_blob = nil
        File.open(tmp_out.path, "rb") do |f|
          new_blob = ActiveStorage::Blob.create_and_upload!(
            io: f,
            filename: new_filename,
            content_type: "image/webp"
          )
        end

        # メタ情報解析は非同期で
        new_blob.analyze_later

        # 順序保持のため、Attachmentのblobを差し替える
        attachment.update!(blob: new_blob)

        # 旧blobがどこにも紐づいていなければ削除
        purge_blob_if_unattached(original_blob)
      ensure
        tmp_out.close!
      end
    end
  rescue => e
    Rails.logger.error "[ConvertGiftImagesToWebpJob] Attachment #{attachment.id} convert error: #{e.class} - #{e.message}"
  end

  def build_webp_filename(original_name)
    base = File.basename(original_name, File.extname(original_name))
    "#{base}.webp"
  end

  def purge_blob_if_unattached(blob)
    return unless blob.present?
    # 他のアタッチメントから参照されていなければ削除
    unless ActiveStorage::Attachment.where(blob_id: blob.id).exists?
      blob.purge_later
    end
  end
end
