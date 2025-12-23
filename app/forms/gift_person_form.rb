class GiftPersonForm
  include ActiveModel::Model

  attr_reader :gift_person, :remind

  def initialize(user:, gift_person_params:, remind_params: nil, line_connected: false)
    raise ArgumentError, "user is required" unless user

    @user = user
    @gift_person_params = normalize_params(gift_person_params)
    @remind_params = normalize_optional_params(remind_params)
    @line_connected = line_connected
    @remind_form_values = extract_remind_form_values(@remind_params)

    build_gift_person
    build_remind
  end

  def save
    ActiveRecord::Base.transaction do
      gift_person.save!
      persist_remind! if remind_should_be_persisted?
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def remind_form_values
    @remind_form_values
  end

  def remind_form_enabled?
    line_connected? && (remind_requested? || remind.errors.any?)
  end

  def line_connected?
    @line_connected
  end

  private

  attr_reader :user, :gift_person_params, :remind_params

  def build_gift_person
    @gift_person = user.gift_people.build(gift_person_params)
  end

  def build_remind
    @remind = user.reminds.build
    apply_form_values_to_remind
  end

  def apply_form_values_to_remind
    remind.notification_at = remind_form_values[:notification_at]
  end

  def persist_remind!
    remind.gift_person = gift_person
    remind.notification_at = remind_form_values[:notification_at]

    days_before = remind_form_values[:notification_days_before]
    time_str = remind_form_values[:notification_time]

    if days_before.blank? || time_str.blank?
      remind.errors.add(:base, "通知日数と通知時刻を設定してください")
      raise ActiveRecord::Rollback
    end

    unless remind.set_notification_sent_at(days_before, time_str)
      raise ActiveRecord::Rollback
    end

    remind.save!
  end

  def remind_should_be_persisted?
    line_connected? && remind_requested?
  end

  def remind_requested?
    remind_form_values.values.compact.any?
  end

  def extract_remind_form_values(values)
    return {}.with_indifferent_access unless values.present?

    values
      .transform_values { |value| value.respond_to?(:presence) ? value.presence : value }
      .with_indifferent_access
  end

  def normalize_params(params)
    return {}.with_indifferent_access unless params.present?

    hash = if params.respond_to?(:to_h)
      params.to_h
    else
      params
    end

    hash.with_indifferent_access
  end

  def normalize_optional_params(params)
    return nil unless params.present?

    normalize_params(params)
  end
end
