class EmbeddingService
  MODEL = "text-embedding-3-small"
  DIMENSIONS = 1536

  def self.client
    @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  # GiftRecordのembeddingを生成してDBに保存する
  def self.generate_and_save(gift_record)
    text = build_text(gift_record)
    vector = embed(text)
    gift_record.update_column(:embedding, vector)
  rescue StandardError => e
    Rails.logger.error "EmbeddingService error for GiftRecord##{gift_record.id}: #{e.message}"
    nil
  end

  # # テキストをベクトルに変換して返す
  # def self.embed(text)
  #   response = client.embeddings(
  #     parameters: {
  #       model: MODEL,
  #       input: text,
  #       dimensions: DIMENSIONS
  #     }
  #   )
  #   response.dig("data", 0, "embedding")
  # end

  # private

  # embeddingの元となるテキストを構築する
  # def self.build_text(gift_record)
  #   parts = [
  #     gift_record.item_name,
  #     gift_record.event&.name,
  #     gift_record.gift_person&.name,
  #     gift_record.gift_direction == "received" ? "もらった" : "あげた",
  #     gift_record.amount ? "#{gift_record.amount}円" : nil,
  #     gift_record.gift_at ? gift_record.gift_at.strftime("%Y年%m月%d日") : nil,
  #     gift_record.memo
  #   ]
  #   parts.compact.join(" ")
  # end
end
