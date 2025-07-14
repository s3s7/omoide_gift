class Relationship < ApplicationRecord
  # リレーション
  has_many :gift_people, dependent: :restrict_with_error
  
  # バリデーション（ベテランバックエンドエンジニアによる堅牢性の確保）
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { case_sensitive: false }
  
  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [nil, '']) }
  scope :ordered, -> { order(:name) }
  
  # インスタンスメソッド
  def display_name
    name.presence || "未設定"
  end
  
  # デフォルト関係性の取得・作成（エラーハンドリング強化版）
  def self.default_relationships
    default_names = [
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
    
    created_count = 0
    error_count = 0
    
    default_names.each do |name|
      begin
        relationship = find_or_create_by(name: name)
        if relationship.persisted?
          created_count += 1
          Rails.logger.debug "Relationship created/found: #{name}"
        else
          error_count += 1
          Rails.logger.error "Failed to create relationship: #{name} - Errors: #{relationship.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        error_count += 1
        Rails.logger.error "Exception creating relationship #{name}: #{e.message}"
      end
    end
    
    Rails.logger.info "Default relationships creation completed: #{created_count} success, #{error_count} errors"
    
    # 作成後の関係性数を確認
    total_relationships = Relationship.count
    Rails.logger.info "Total relationships in database: #{total_relationships}"
    
    if total_relationships == 0
      Rails.logger.error "CRITICAL: No relationships exist in database after default_relationships creation!"
    end
    
    total_relationships
  rescue StandardError => e
    Rails.logger.error "Critical error in default_relationships: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    0
  end
  
  # デバッグ用メソッド
  def self.debug_relationships_info
    Rails.logger.info "=== Relationships Debug Information ==="
    Rails.logger.info "Total relationships: #{Relationship.count}"
    Rails.logger.info "Active relationships: #{Relationship.active.count}"
    Rails.logger.info "Relationship names: #{Relationship.pluck(:name).join(', ')}"
    
    if Relationship.count > 0
      Rails.logger.info "Sample relationship: #{Relationship.first.inspect}"
    else
      Rails.logger.error "No relationships found in database!"
    end
    Rails.logger.info "========================================="
  end
end
