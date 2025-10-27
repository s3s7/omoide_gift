module RemindFactoryHelpers
  def self.next_valid_notification_time(from_time)
    time = from_time.change(sec: 0)

    rounded_time = if time.min.zero? || time.min == 30
      time
    elsif time.min < 30
      time.change(min: 30)
    else
      (time + 1.hour).change(min: 0)
    end

    if rounded_time.hour < 6
      rounded_time = rounded_time.change(hour: 6, min: 0)
    elsif rounded_time.hour > 23 || (rounded_time.hour == 23 && rounded_time.min > 30)
      rounded_time = (rounded_time + 1.day).change(hour: 6, min: 0)
    end

    rounded_time
  end
end

FactoryBot.define do
  factory :remind do
    association :user
    association :gift_person

    transient do
      notification_offset_minutes { 60 }
    end

    notification_sent_at do
      base_time = Time.current + notification_offset_minutes.minutes
      RemindFactoryHelpers.next_valid_notification_time(base_time)
    end

    notification_at { notification_sent_at.in_time_zone.to_date }
    is_sent { false }
  end
end
