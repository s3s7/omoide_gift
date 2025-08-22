# 管理者用システム統計コントローラー
class Admin::StatisticsController < Admin::BaseController
  def index
    @statistics = build_detailed_statistics
    log_admin_action("システム統計表示")
  end

  private

  def build_detailed_statistics
    Rails.logger.info "=== 統計データ構築開始 ==="
    Rails.logger.info "現在の年: #{Date.current.year}"
    Rails.logger.info "総ユーザー数: #{User.count}"
    Rails.logger.info "総ギフト記録数: #{GiftRecord.count}"
    Rails.logger.info "総コメント数: #{Comment.count}"
    
    stats = {
      users: build_user_statistics,
      gift_records: build_gift_record_statistics,
      comments: build_comment_statistics,
      activity: build_activity_statistics
    }
    
    Rails.logger.info "=== 統計データ構築完了 ==="
    stats
  end

  def build_user_statistics
    # 基本統計を効率的に取得
    user_counts = User.group(:role).count
    provider_counts = User.group("provider IS NOT NULL").count

    # 月別登録数を効率的に取得
    current_year = Date.current.year
    year_start = Time.zone.local(current_year, 1, 1).beginning_of_day
    year_end = Time.zone.local(current_year, 12, 31).end_of_day

    Rails.logger.info "ユーザー統計: #{current_year}年の範囲 #{year_start} - #{year_end}"

    monthly_data = User.where(created_at: year_start..year_end)
                      .group("EXTRACT(month FROM created_at)")
                      .count

    Rails.logger.info "月別ユーザー登録データ: #{monthly_data}"

    # EXTRACTの結果は文字列または数値の可能性があるため、両方チェック
    monthly_registrations = (1..12).map do |month|
      monthly_data[month.to_f] || monthly_data[month.to_s] || monthly_data[month] || 0
    end

    Rails.logger.info "月別登録配列: #{monthly_registrations}"

    {
      total: User.count,
      admins: user_counts["admin"] || 0,
      general: user_counts["general"] || 0,
      line_users: provider_counts[true] || 0,
      email_users: provider_counts[false] || 0,
      monthly_registrations: monthly_registrations
    }
  rescue => e
    Rails.logger.error "統計データ取得エラー (ユーザー): #{e.message}"
    Rails.logger.error "スタックトレース: #{e.backtrace.first(5).join("\n")}"
    {
      total: 0,
      admins: 0,
      general: 0,
      line_users: 0,
      email_users: 0,
      monthly_registrations: Array.new(12, 0)
    }
  end

  def build_gift_record_statistics
    # 基本統計を効率的に取得
    public_counts = GiftRecord.group(:is_public).count

    # 月別投稿数を効率的に取得
    current_year = Date.current.year
    year_start = Time.zone.local(current_year, 1, 1).beginning_of_day
    year_end = Time.zone.local(current_year, 12, 31).end_of_day

    Rails.logger.info "ギフト記録統計: #{current_year}年の範囲 #{year_start} - #{year_end}"

    monthly_data = GiftRecord.where(created_at: year_start..year_end)
                            .group("EXTRACT(month FROM created_at)")
                            .count

    Rails.logger.info "月別ギフト記録データ: #{monthly_data}"

    # EXTRACTの結果は文字列または数値の可能性があるため、両方チェック
    monthly_posts = (1..12).map do |month|
      monthly_data[month.to_f] || monthly_data[month.to_s] || monthly_data[month] || 0
    end

    Rails.logger.info "月別投稿配列: #{monthly_posts}"

    {
      total: GiftRecord.count,
      public: public_counts[true] || 0,
      private: public_counts[false] || 0,
      with_images: GiftRecord.joins(:images_attachments).distinct.count,
      monthly_posts: monthly_posts
    }
  rescue => e
    Rails.logger.error "統計データ取得エラー (ギフト記録): #{e.message}"
    Rails.logger.error "スタックトレース: #{e.backtrace.first(5).join("\n")}"
    {
      total: 0,
      public: 0,
      private: 0,
      with_images: 0,
      monthly_posts: Array.new(12, 0)
    }
  end

  def build_comment_statistics
    # 月別コメント数を効率的に取得
    current_year = Date.current.year
    year_start = Time.zone.local(current_year, 1, 1).beginning_of_day
    year_end = Time.zone.local(current_year, 12, 31).end_of_day
    
    Rails.logger.info "コメント統計: #{current_year}年の範囲 #{year_start} - #{year_end}"
    
    monthly_data = Comment.where(created_at: year_start..year_end)
                         .group("EXTRACT(month FROM created_at)")
                         .count
    
    Rails.logger.info "月別コメントデータ: #{monthly_data}"
    
    # EXTRACTの結果は文字列または数値の可能性があるため、両方チェック
    monthly_comments = (1..12).map do |month|
      monthly_data[month.to_f] || monthly_data[month.to_s] || monthly_data[month] || 0
    end
    
    Rails.logger.info "月別コメント配列: #{monthly_comments}"

    {
      total: Comment.count,
      monthly_comments: monthly_comments
    }
  rescue => e
    Rails.logger.error "統計データ取得エラー (コメント): #{e.message}"
    Rails.logger.error "スタックトレース: #{e.backtrace.first(5).join("\n")}"
    {
      total: 0,
      monthly_comments: Array.new(12, 0)
    }
  end

  def build_activity_statistics
    {
      favorites: Favorite.count,
      reminds: Remind.count,
      gift_people: GiftPerson.count
    }
  rescue => e
    Rails.logger.error "統計データ取得エラー (アクティビティ): #{e.message}"
    {
      favorites: 0,
      reminds: 0,
      gift_people: 0
    }
  end

  # EXTRACT関数がうまく動作しない場合の代替方法
  def calculate_monthly_data_alternative(model, year_start, year_end)
    Rails.logger.info "代替方式で月別データを計算: #{model.name}"
    
    (1..12).map do |month|
      month_start = Time.zone.local(Date.current.year, month, 1).beginning_of_month
      month_end = month_start.end_of_month
      count = model.where(created_at: month_start..month_end).count
      Rails.logger.debug "#{month}月: #{count}件"
      count
    end
  rescue => e
    Rails.logger.error "代替方式でのエラー: #{e.message}"
    Array.new(12, 0)
  end
end
