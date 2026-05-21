namespace :embeddings do
  desc "Generate embeddings for all GiftRecords that don't have one"
  task backfill: :environment do
    records = GiftRecord.where(embedding: nil)
    total = records.count

    puts "=== Embedding Backfill ==="
    puts "対象レコード数: #{total}"
    puts "OPENAI_API_KEY: #{ENV['OPENAI_API_KEY'].present? ? '設定済み' : '未設定'}"

    if ENV["OPENAI_API_KEY"].blank?
      puts "ERROR: OPENAI_API_KEY が設定されていません"
      exit 1
    end

    success = 0
    failed = 0

    records.find_each do |record|
      retries = 0
      begin
        text = [
          record.item_name,
          record.event&.name,
          record.gift_person&.name,
          record.gift_direction == "received" ? "もらった" : "あげた",
          record.amount ? "#{record.amount}円" : nil,
          record.gift_at ? record.gift_at.strftime("%Y年%m月%d日") : nil,
          record.memo
        ].compact.join(" ")

        vector = EmbeddingService.embed(text)
        record.update_column(:embedding, vector)
        success += 1
        sleep 20
      rescue StandardError => e
        if e.message.include?("429") && retries < 3
          wait = 60 * (retries + 1)
          puts "  RETRY: GiftRecord##{record.id} (#{wait}秒待機)"
          sleep wait
          retries += 1
          retry
        end
        failed += 1
        puts "  ERROR: GiftRecord##{record.id} - #{e.message}"
      end
    end

    puts "完了: #{success}件成功 / #{failed}件失敗 / #{total}件中"
    puts "========================="
  end
end
