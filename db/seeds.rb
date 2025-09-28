# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ===== イベントデータの作成 =====
puts "イベントデータを作成中..."

event_names = [
  '誕生日',
  '母の日',
  '父の日',
  '敬老の日',
  'クリスマス',
  'バレンタインデー',
  'ホワイトデー',
  'お中元',
  'お歳暮',
  '結婚祝い',
  '出産祝い',
  '入学祝い',
  '卒業祝い',
  'その他'
]

# event_names.each_with_index do |event_name, index|
#   event = Event.find_or_create_by(name: event_name)
#   # 既にpositionが設定されている場合はスキップ（重複を避けるため）
#   next if event.position.present? && event.position == (index + 1)
#   event.update!(position: index + 1)
# end

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
  '息子',
  '娘',
  '義父',
  '義母',
  '配偶者',
  '友人',
  '恋人',
  '上司',
  '同僚',
  'その他'
]


# relationship_names.each_with_index do |relationship_name, index|
#   relationship = Relationship.find_or_create_by(name: relationship_name)
#   # 既にpositionが設定されている場合はスキップ（重複を避けるため）
#   next if relationship.position.present? && relationship.position == (index + 1)
#   relationship.update!(position: index + 1)
# end

puts "関係性データの作成完了: #{Relationship.count}件の関係性が存在します"

# ===== アイテムカテゴリーの作成 =====
puts "アイテムカテゴリーを作成中..."

gift_item_categories = [
  'ドリンク',
  'スイーツ',
  'フード',
  'お酒',
  'ビューティー・ヘルスケア',
  'インテリア・雑貨',
  '花',
  'キッチン・家事',
  'ファッション',
  'スポーツ',
  'ベビー・キッズ',
  'ペット',
  'エンタメ・趣味',
  'ギフトカード',
  'レジャー施設',
  'トラベル・ホテル',
  'カタログギフト',
  '体験ギフト',
  '写真',
  'その他'
]

gift_item_categories.each do |name|
  GiftItemCategory.find_or_create_by(name: name)
end

puts "アイテムカテゴリーの作成完了: #{GiftItemCategory.count}件のカテゴリが存在します"

if Rails.env.production?
admin_email = ENV['ADMIN_EMAIL']
admin_password = ENV['ADMIN_PASSWORD']
admin_name = ENV['ADMIN_NAME']

User.find_or_create_by(email: admin_email) do |user|
user.name = admin_name
user.password = admin_password
user.role = 'admin'
end

puts "Admin user seeded for production"
end

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

puts "\nシードデータの作成が完了しました！"
