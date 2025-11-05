module WebpConvertible
  extend ActiveSupport::Concern

  class_methods do
    def webp_convert_for(*attachment_names)
      class_attribute :webp_convert_attachment_names, instance_writer: false, default: []
      self.webp_convert_attachment_names += attachment_names.map(&:to_sym)
      after_commit :enqueue_webp_conversion, on: [ :create, :update ]
    end
  end

  # 汎用: 指定された添付に対して必要時のみWebP変換ジョブを投入
  def enqueue_webp_conversion
    names = self.class.try(:webp_convert_attachment_names) || []
    names.each do |name|
      next unless respond_to?(name)
      attachment_assoc = public_send(name)

      next unless attachment_assoc.respond_to?(:attached?) && attachment_assoc.attached?

      needs_conversion = false

      if attachment_assoc.is_a?(ActiveStorage::Attached::Many)
        needs_conversion = attachment_assoc.attachments.any? do |attachment|
          begin
            blob = attachment.blob
            blob.present? && blob.content_type.to_s != "image/webp"
          rescue
            false
          end
        end
      else
        begin
          blob = attachment_assoc.blob
          needs_conversion = blob.present? && blob.content_type.to_s != "image/webp"
        rescue
          needs_conversion = false
        end
      end

      ConvertAttachmentsToWebpJob.perform_later(self.class.name, id, name.to_s) if needs_conversion
    end
  end
end
