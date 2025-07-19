# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ===== イベントデータの作成（ベテランバックエンドエンジニアによる包括的実装） =====
puts "イベントデータを作成中..."

event_names = [
  '誕生日',
  '母の日',
  '父の日',
  '敬老の日',
  'お中元',
  'お歳暮',
  '結婚祝い',
  '出産祝い',
  '入学祝い',
  '卒業祝い',
  'その他'
]

event_names.each do |event_name|
  Event.find_or_create_by(name: event_name)
end

puts "イベントデータの作成完了: #{Event.count}件のイベントが存在します"

# ===== 関係性データの作成 =====
puts "関係性データを作成中..."

relationship_names = [
  '父',
  '母',
  '兄',
  '姉',
  '弟',
  '妹',
  '祖父',
  '祖母',
  '義父',
  '義母',
  '配偶者',
  '友人',
  '恋人',
  '上司',
  '同僚',
  'その他'
]

relationship_names.each do |relationship_name|
  Relationship.find_or_create_by(name: relationship_name)
end

puts "関係性データの作成完了: #{Relationship.count}件の関係性が存在します"

# ===== 年齢データの作成 =====
puts "年齢データを作成中..."

age_groups = [
  "10代未満",
  "10代",
  "20代",
  "30代",
  "40代",
  "50代",
  "60代",
  "70代",
  "80代",
  "90代以上"
]

age_groups.each do |age_group|
  Age.find_or_create_by(year: age_group)
end

puts "年齢データの作成完了: #{Age.count}件の年齢グループが存在します"

# ===== データ整合性チェック =====
puts "\n=== データ整合性チェック ==="
puts "Events count: #{Event.count}"
puts "Relationships count: #{Relationship.count}"
puts "Ages count: #{Age.count}"
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

if Age.count == 0
  puts "⚠️  WARNING: 年齢データが0件です！"
else
  puts "✓ 年齢データが正常に存在します"
end

puts "\nシードデータの作成が完了しました！"
