module AgeFilterable
  extend ActiveSupport::Concern

  # 年代キーとレンジ定義
  # 年代キーから生年月日の範囲を返す
  # return: [from_date, to_date]
  # - from_date/to_date のどちらかが nil の場合あり（80代以上など）
  def birthday_range_for(age_group, reference_date = Date.current)
    group = {
      "10s" => [ 10, 19 ],
      "20s" => [ 20, 29 ],
      "30s" => [ 30, 39 ],
      "40s" => [ 40, 49 ],
      "50s" => [ 50, 59 ],
      "60s" => [ 60, 69 ],
      "70s" => [ 70, 79 ],
      "80plus" => [ 80, nil ]
    }[age_group.to_s]
    return [ nil, nil ] unless group

    min_age, max_age = group

    if max_age.nil?
      # 80代以上: 誕生日 <= today - 80年
      to = reference_date.years_ago(min_age)
      [ nil, to ]
    else
      # 例: 20-29歳 → [today-30y+1d, today-20y]
      from = (reference_date.years_ago(max_age + 1)) + 1.day
      to   = reference_date.years_ago(min_age)
      [ from, to ]
    end
  end
end
