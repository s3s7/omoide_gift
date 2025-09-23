module GiftRecordsHelper
  def default_gift_direction_checked?(gift_record, direction)
    if gift_record.new_record?
      # 新規作成時は、モデルに設定済みの値を優先
      if gift_record.gift_direction.present?
        case direction
        when :received
          gift_record.gift_direction.to_s == "received"
        when :given
          gift_record.gift_direction.to_s == "given"
        end
      else
        # 設定が無い場合のみデフォルトは贈った側
        direction == :given
      end
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

  def gift_direction_value(gift_record)
    if gift_record.new_record?
      # 新規時は属性を尊重（未設定ならgiven）
      gift_record.gift_direction.present? ? gift_record.gift_direction.to_s : "given"
    else
      gift_record.received? ? "received" : "given"
    end
  end

  def gift_direction_display_text(gift_record)
    gift_record.received? ? "もらったギフト" : "贈ったギフト"
  end

  def gift_direction_description_text(gift_record)
    if gift_record.received?
      "このユーザーが受け取ったギフトです"
    else
      "このユーザーが贈ったギフトです"
    end
  end

  def gift_direction_icon_class(gift_record)
    gift_record.received? ? "fas fa-hand-holding-heart" : "fas fa-gift"
  end

  def gift_direction_color(gift_record)
    gift_record.received? ? "#FF6B6B" : "#28a745"
  end
end
