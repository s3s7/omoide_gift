module DisplayNameable
  extend ActiveSupport::Concern

  included do
    class_attribute :display_name_fallback, instance_writer: false, default: "未設定"
  end

  def display_name
    name.presence || self.class.display_name_fallback
  end
end
