module GiftRecordsHelper
 def default_gift_direction_checked?(gift_record, direction)
    if gift_record.new_record?
      # 新規作成時のデフォルト値
      direction == :given
    else
      # 編集時は現在の値
      case direction
      when :received
        gift_record.received?
      when :given
        gift_record.given?
      end
    end
  end
end
