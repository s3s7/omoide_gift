# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ===== イベントデータの作成（ベテランバックエンドエンジニアによる包括的実装） =====
puts "イベントデータを作成中..."

# モデルのdefault_eventsメソッドを使用
events_count = Event.default_events
puts "イベントデータの作成完了: #{events_count}件のイベントが存在します"

# ===== 関係性データの作成 =====
puts "関係性データを作成中..."

# モデルのdefault_relationshipsメソッドを使用
relationships_count = Relationship.default_relationships
puts "関係性データの作成完了: #{relationships_count}件の関係性が存在します"

# ===== データ整合性チェック =====
puts "\n=== データ整合性チェック ==="
puts "Events count: #{Event.count}"
puts "Relationships count: #{Relationship.count}"
puts "Users count: #{User.count}"

if Event.count == 0
  puts "⚠️  WARNING: イベントデータが0件です！"
else
  puts "✓ イベントデータが正常に存在します"
end

if Relationship.count == 0
  puts "⚠️  WARNING: 関係性データが0件です！"
else
  puts "✓ 関係性データが正常に存在します"
end

puts "\nシードデータの作成が完了しました！"
