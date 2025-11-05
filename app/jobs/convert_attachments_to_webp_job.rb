class ConvertAttachmentsToWebpJob < ApplicationJob
  queue_as :default

  # 任意モデルの添付(avatar/images など)をWebPへ変換
  # attachment_names: String または Array<String>
  def perform(record_class, record_id, attachment_names)
    names = Array(attachment_names).map(&:to_s)
    record = safe_find(record_class, record_id)
    return unless record

    names.each do |name|
      attachable = fetch_attachable(record, name)
      next unless attachable

      attachments = collect_attachments(attachable)
      attachments.each { |att| WebpConversionService.convert_attachment!(att) }
    end
  rescue => e
    Rails.logger.error "[ConvertAttachmentsToWebpJob] Error: #{e.class} - #{e.message} (#{record_class}##{record_id})"
  end

  private

  def safe_find(klass_name, id)
    klass_name.constantize.find_by(id: id)
  rescue NameError
    Rails.logger.error "[ConvertAttachmentsToWebpJob] Unknown class: #{klass_name}"
    nil
  end

  def fetch_attachable(record, name)
    return nil unless record.respond_to?(name)
    record.public_send(name)
  end

  def collect_attachments(attachable)
    if attachable.respond_to?(:attachments)
      Array(attachable.attachments).compact
    elsif attachable.respond_to?(:attachment)
      [ attachable.attachment ].compact
    else
      []
    end
  end
end
