class WebpConversionService
  # 指定のActiveStorage::AttachmentをWebPへ変換し、blobを差し替える
  # - 非画像/既にWebPはスキップ
  # - 旧blobは未参照ならpurge_later
  def self.convert_attachment!(attachment, quality: 85)
    return unless attachment.is_a?(ActiveStorage::Attachment)

    blob = attachment.blob
    return unless blob.present?
    return unless blob.content_type.to_s.start_with?("image/")
    return if blob.content_type.to_s == "image/webp" || attachment.filename.to_s.downcase.end_with?(".webp")

    original_blob = blob

    blob.open do |file|
      require "mini_magick"
      image = MiniMagick::Image.open(file.path)
      image.auto_orient
      image.strip

      tmp_out = Tempfile.new([ "attachment_#{attachment.id}", ".webp" ])
      tmp_out.binmode
      begin
        image.format("webp") { |c| c.quality quality.to_s }
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
        new_blob.analyze_later

        attachment.update!(blob: new_blob)
        purge_blob_if_unattached(original_blob)
      ensure
        tmp_out.close!
      end
    end
  rescue => e
    Rails.logger.error "[WebpConversionService] convert_attachment! error: #{e.class} - #{e.message} (attachment_id=#{attachment&.id})"
  end

  def self.build_webp_filename(original_name)
    base = File.basename(original_name, File.extname(original_name))
    "#{base}.webp"
  end

  def self.purge_blob_if_unattached(blob)
    return unless blob.present?
    unless ActiveStorage::Attachment.where(blob_id: blob.id).exists?
      blob.purge_later
    end
  end

  private_class_method :build_webp_filename, :purge_blob_if_unattached
end
