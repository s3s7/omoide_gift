class EmbeddingService
  MODEL = "text-embedding-3-small"
  DIMENSIONS = 1536

  # GiftRecordのembeddingを生成してDBに保存する
  def self.generate_and_save(gift_record)
    text = build_text(gift_record)
    vector = embed(text)
    gift_record.update_column(:embedding, vector)
  end

  # テキストをベクトルに変換して返す
  def self.embed(text)
    raise ArgumentError, "text is blank" if text.blank?

    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: MODEL,
        input: text,
        dimensions: DIMENSIONS
      }
    )
    embedding = response.dig("data", 0, "embedding")
    raise "OpenAI embedding missing in response: #{response.inspect}" unless embedding

    embedding
  end

  class << self
    private

    # embeddingの元となるテキストを構築する
    def build_text(gift_record)
      parts = [
        gift_record.item_name,
        gift_record.event&.name,
        gift_record.gift_person&.name,
        gift_record.gift_direction == "received" ? "もらった" : "あげた",
        gift_record.amount ? "#{gift_record.amount}円" : nil,
        gift_record.gift_at ? gift_record.gift_at.strftime("%Y年%m月%d日") : nil,
        gift_record.memo
      ]
      parts.compact.join(" ")
    end
  end
end
