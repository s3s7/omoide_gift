module GiftPeopleHelper
  # ギフト相手の表示名を生成
  def gift_person_display_name(gift_person)
    return "未設定" unless gift_person&.name.present?
    name = gift_person.name
    if gift_person.relationship&.name.present?
      "#{name}（#{gift_person.relationship.name}）"
    else
      name
    end
  end

  # ギフト相手の年齢を計算
  def gift_person_age(gift_person)
    return nil unless gift_person&.birthday.present?
    ((Date.current - gift_person.birthday) / 365.25).to_i
  end

  # 次の誕生日までの日数を計算
  def days_until_birthday(gift_person)
    return nil unless gift_person&.birthday.present?
    today = Date.current
    this_year_birthday = Date.new(today.year, gift_person.birthday.month, gift_person.birthday.day)
    next_birthday = this_year_birthday < today ? this_year_birthday.next_year : this_year_birthday
    (next_birthday - today).to_i
  end

  # ギフト相手の統計情報を取得
  def gift_person_stats(gift_person, user)
    gift_records = user.gift_records.where(gift_people_id: gift_person.id)
    {
      total_gifts: gift_records.count,
      last_gift_date: gift_records.maximum(:gift_at),
      first_gift_date: gift_records.minimum(:gift_at)
    }
  end

  # ギフト相手のステータスバッジを生成
  def gift_person_status_badge(gift_person, user)
    stats = gift_person_stats(gift_person, user)
    if stats[:total_gifts] == 0
      content_tag :span, "未記録", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    elsif stats[:last_gift_date] && stats[:last_gift_date] > 1.month.ago
      content_tag :span, "最近活動", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    else
      content_tag :span, "記録あり", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
    end
  end
end
