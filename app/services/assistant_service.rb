class AssistantService
  MODEL = "gpt-4o-mini"

  def self.chat(query:, user:)
    return { answer: nil, records: [] } if ENV["OPENAI_API_KEY"].blank?

    records = GiftRecordSearchService.search(query: query, user: user)
    context = build_context(records)
    answer = call_openai(query: query, context: context)
    { answer: answer, records: records }
  rescue StandardError => e
    Rails.logger.error "AssistantService error: #{e.message}"
    { answer: nil, records: [] }
  end

  class << self
    private

    def build_context(records)
      return "関連するギフト記録はありません。" if records.empty?

      records.map.with_index(1) do |r, i|
        parts = [
          "【記録#{i}】",
          "アイテム: #{r.item_name}",
          r.gift_person ? "相手: #{r.gift_person.name}" : nil,
          r.event ? "イベント: #{r.event.name}" : nil,
          "種別: #{r.gift_direction == 'received' ? 'もらった' : 'あげた'}",
          r.amount ? "金額: #{r.amount}円" : nil,
          r.gift_at ? "日付: #{r.gift_at.strftime('%Y年%m月%d日')}" : nil,
          r.memo.present? ? "メモ: #{r.memo}" : nil
        ]
        parts.compact.join(" / ")
      end.join("\n")
    end

    def call_openai(query:, context:)
      system_prompt = <<~PROMPT
        あなたはギフト記録管理アプリのアシスタントです。
        ユーザーのギフト記録データをもとに、質問に答えてください。
        以下は関連するギフト記録です：

        #{context}

        回答は日本語で、簡潔かつ親切にしてください。
        記録に基づいて提案・アドバイスする場合は、記録の内容を踏まえた上で積極的に提案してください。
        記録が全くない場合のみ「記録にありません」と伝えてください。
      PROMPT

      response = OpenAI::Client.new.chat(
        parameters: {
          model: MODEL,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: query }
          ],
          temperature: 0.7
        }
      )
      response.dig("choices", 0, "message", "content")
    end
  end
end
