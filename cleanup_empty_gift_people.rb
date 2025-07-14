# 空のGiftPersonレコードを削除するスクリプト
puts "空のGiftPersonレコードをチェックしています..."

empty_gift_people = GiftPerson.where("name IS NULL OR name = '' OR name ~ '^\\s*$'")
count = empty_gift_people.count

puts "#{count}件の空のGiftPersonレコードが見つかりました"

if count > 0
  puts "削除中..."
  empty_gift_people.destroy_all
  puts "#{count}件のレコードを削除しました"
else
  puts "削除するレコードはありません"
end

puts "完了"