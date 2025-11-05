module AvatarAttachable
  extend ActiveSupport::Concern

  included do
    validate :avatar_validation

    class_attribute :avatar_content_types, instance_writer: false, default: %w[image/jpeg image/jpg image/png image/webp]
    class_attribute :avatar_max_size, instance_writer: false, default: 5.megabytes
  end

  def avatar_url
    return unless respond_to?(:avatar) && avatar.attached? && avatar.blob&.persisted? && persisted?

    avatar
  rescue ActiveRecord::RecordNotFound, NoMethodError => e
    Rails.logger.warn "#{self.class.name} avatar access failed: #{e.message}"
    nil
  end

  def has_avatar?
    respond_to?(:avatar) && avatar.attached? && avatar.blob&.persisted?
  end

  private

  def avatar_validation
    return unless respond_to?(:avatar) && avatar.attached?

    unless avatar.content_type.in?(self.class.avatar_content_types)
      errors.add(:avatar, "はJPEG、PNG、WEBP形式のファイルのみアップロードできます")
    end

    if avatar.blob.byte_size > self.class.avatar_max_size
      errors.add(:avatar, "のファイルサイズは#{self.class.avatar_max_size / 1.megabyte}MB以下にしてください")
    end
  rescue StandardError => e
    Rails.logger.error "#{self.class.name} avatar validation error: #{e.message}"
    errors.add(:avatar, "の検証中にエラーが発生しました")
  end

end
