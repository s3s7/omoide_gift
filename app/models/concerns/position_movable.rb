module PositionMovable
  extend ActiveSupport::Concern

  MIN_POSITION = 1
  POSITION_STEP = 1
  TEMP_SWAP_POSITION = 0

  included do
    validates :position, presence: true, uniqueness: true
    scope :ordered, -> { order(:position) }
  end

  def move_up!
    return if position.to_i <= MIN_POSITION

    swap_positions!(position - POSITION_STEP)
  end

  def move_down!
    max_position = self.class.maximum(:position)
    return if max_position.nil? || position.to_i >= max_position

    swap_positions!(position + POSITION_STEP)
  end

  private

  def swap_positions!(target_position)
    target = self.class.find_by(position: target_position)
    return unless target

    self.class.transaction do
      current_position = position
      update!(position: TEMP_SWAP_POSITION)
      target.update!(position: current_position)
      update!(position: target_position)
    end
  end
end
