class Event < ApplicationRecord
  # リレーション
  has_many :gift_records, dependent: :nullify
  
  # バリデーション（ベテランバックエンドエンジニアによる堅牢性の確保）
  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { case_sensitive: false }
  
  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [nil, '']) }
  scope :ordered, -> { order(:name) }
  scope :frequently_used, -> { 
    joins(:gift_records)
      .group(:id)
      .order('COUNT(gift_records.id) DESC')
  }
  
  # インスタンスメソッド
  def display_name
    name.presence || "未設定"
  end
  
  # ギフト記録数を取得
  def gift_records_count
    gift_records.count
  end
  
  # クラスメソッド（よく使われるイベントの取得）
  def self.popular_events(limit = 5)
    frequently_used.limit(limit)
  end
  
  # デフォルトイベントの取得・作成（エラーハンドリング強化版）
  def self.default_events
    default_names = [
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
    
    created_count = 0
    error_count = 0
    
    default_names.each do |name|
      begin
        event = find_or_create_by(name: name)
        if event.persisted?
          created_count += 1
          Rails.logger.debug "Event created/found: #{name}"
        else
          error_count += 1
          Rails.logger.error "Failed to create event: #{name} - Errors: #{event.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        error_count += 1
        Rails.logger.error "Exception creating event #{name}: #{e.message}"
      end
    end
    
    Rails.logger.info "Default events creation completed: #{created_count} success, #{error_count} errors"
    
    # 作成後のイベント数を確認
    total_events = Event.count
    Rails.logger.info "Total events in database: #{total_events}"
    
    if total_events == 0
      Rails.logger.error "CRITICAL: No events exist in database after default_events creation!"
    end
    
    total_events
  rescue StandardError => e
    Rails.logger.error "Critical error in default_events: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    0
  end
  
  # デバッグ用メソッド
  def self.debug_events_info
    Rails.logger.info "=== Events Debug Information ==="
    Rails.logger.info "Total events: #{Event.count}"
    Rails.logger.info "Active events: #{Event.active.count}"
    Rails.logger.info "Event names: #{Event.pluck(:name).join(', ')}"
    
    if Event.count > 0
      Rails.logger.info "Sample event: #{Event.first.inspect}"
    else
      Rails.logger.error "No events found in database!"
    end
    Rails.logger.info "================================="
  end
end
