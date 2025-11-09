class GiftRecordForm
  include ActiveModel::Model

  attr_reader :gift_record, :gift_person

  def initialize(user:, gift_record_params:, gift_person_params: nil, gift_direction_default: nil, forced_gift_direction: nil)
    raise ArgumentError, "user is required" unless user

    @user = user
    @gift_record_params = normalize_params(gift_record_params)
    @gift_person_params = normalize_optional_params(gift_person_params)
    @gift_direction_default = normalize_direction(gift_direction_default) || :given
    @forced_gift_direction = normalize_direction(forced_gift_direction)

    build_gift_record
    build_gift_person_if_needed
  end

  def save
    ActiveRecord::Base.transaction do
      persist_gift_person_if_needed!
      gift_record.save!
    end

    true
  rescue ActiveRecord::RecordInvalid
    cleanup_new_gift_person
    false
  end

  def creating_new_gift_person?
    gift_people_id_param == "new"
  end

  private

  attr_reader :user, :gift_record_params, :gift_person_params, :gift_direction_default, :forced_gift_direction

  def build_gift_record
    @gift_record = user.gift_records.build(gift_record_attributes)
    apply_gift_direction!
  end

  def build_gift_person_if_needed
    return unless creating_new_gift_person?

    @gift_person = user.gift_people.build(gift_person_attributes)
  end

  def gift_record_attributes
    return gift_record_params.except(:gift_people_id) if creating_new_gift_person?

    gift_record_params
  end

  def gift_person_attributes
    gift_person_params || {}
  end

  def persist_gift_person_if_needed!
    return unless creating_new_gift_person?

    gift_person.save!
    gift_record.gift_person = gift_person
  end

  def cleanup_new_gift_person
    return unless creating_new_gift_person?
    return unless gift_person&.persisted?

    gift_person.destroy
  rescue StandardError
    # no-op: cleanup best-effort
  end

  def apply_gift_direction!
    if forced_gift_direction.present?
      gift_record.gift_direction = forced_gift_direction
    elsif gift_record.gift_direction.blank?
      gift_record.gift_direction = gift_direction_default
    end
  end

  def gift_people_id_param
    @gift_people_id_param ||= gift_record_params[:gift_people_id].to_s
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

  def normalize_direction(value)
    return nil if value.blank?

    symbol = value.respond_to?(:to_sym) ? value.to_sym : value
    return symbol if %i[given received].include?(symbol)

    nil
  end
end
