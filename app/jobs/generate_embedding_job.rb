class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(gift_record_id)
    gift_record = GiftRecord.find_by(id: gift_record_id)
    return unless gift_record
    EmbeddingService.generate_and_save(gift_record)
  end
end
