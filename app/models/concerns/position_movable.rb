module PositionMovable
  extend ActiveSupport::Concern

  included do
    validates :position, presence: true, uniqueness: true
    scope :ordered, -> { order(:position) }
  end

  def move_up!
    return if position.to_i <= 1

    swap_positions!(position - 1)
  end

  def move_down!
    max_position = self.class.maximum(:position)
    return if max_position.nil? || position.to_i >= max_position

    swap_positions!(position + 1)
  end

  private

  def swap_positions!(target_position)
    target = self.class.find_by(position: target_position)
    return unless target

    self.class.transaction do
      current_position = position
      update!(position: 0)
      target.update!(position: current_position)
      update!(position: target_position)
    end
  end
end
