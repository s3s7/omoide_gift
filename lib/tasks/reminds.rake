namespace :reminds do
  desc "Send LINE notification for due reminders"
  task send_notifications: :environment do
    service = LineNotificationService.new
    results = service.send_due_reminders
    
    puts "=== Reminder Notification Results ==="
    puts "Total reminders processed: #{results[:total]}"
    puts "Successful: #{results[:success]}"
    puts "Failed: #{results[:failed]}"
    puts "=================================="
  end
  
  desc "Test reminder notification system (debug mode)"
  task test: :environment do
    puts "=== Testing Reminder System ==="
    puts "Current time: #{Time.current}"
    puts "Current timezone: #{Time.zone.name}"
    
    # 今日の範囲のリマインダーを表示
    due_reminds = Remind.due_today.includes(:user, gift_person: :relationship)
    puts "\nFound #{due_reminds.count} due reminders for today:"
    
    due_reminds.each do |remind|
      puts "  ID: #{remind.id}"
      puts "  User: #{remind.user.name} (Provider: #{remind.user.provider}, UID: #{remind.user.uid})"
      puts "  Gift Person: #{remind.gift_person.name}"
      puts "  Notification At: #{remind.notification_at}"
      puts "  Notification Sent At: #{remind.notification_sent_at}"
      puts "  Is Sent: #{remind.is_sent?}"
      puts "  Should Notify: #{remind.should_notify?}"
      puts "  Days Until Notify: #{remind.days_until_notify}"
      puts "  ---"
    end
    
    # 全ての未送信リマインダーを表示
    all_unsent = Remind.unsent.includes(:user, gift_person: :relationship)
    puts "\nAll unsent reminders (#{all_unsent.count}):"
    all_unsent.each do |remind|
      puts "  ID: #{remind.id}, Notification Sent At: #{remind.notification_sent_at}, Should Notify: #{remind.should_notify?}"
    end
    
    puts "\n=== Test completed ==="
  end
end