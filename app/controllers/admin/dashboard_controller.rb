# 管理者ダッシュボードコントローラー
# システム統計情報と管理者向けクイックアクションを提供
class Admin::DashboardController < Admin::BaseController

  def index
    # システム統計情報を取得
    @statistics = build_system_statistics
    
    # 最近の活動情報を取得
    @recent_activities = build_recent_activities
    
    # アラート情報を取得（問題のあるコンテンツなど）
    @alerts = build_admin_alerts

    log_admin_action("ダッシュボード表示")
  end

  private

  # システム統計情報を構築
  def build_system_statistics
    {
      # ユーザー統計
      total_users: User.count,
      admin_users: User.admin.count,
      general_users: User.general.count,
      new_users_this_month: User.where(created_at: 1.month.ago..Time.current).count,
      
      # ギフト記録統計  
      total_gift_records: GiftRecord.count,
      public_gift_records: GiftRecord.where(is_public: true).count,
      private_gift_records: GiftRecord.where(is_public: false).count,
      gift_records_this_month: GiftRecord.where(created_at: 1.month.ago..Time.current).count,
      
      # コメント統計
      total_comments: Comment.count,
      comments_this_month: Comment.where(created_at: 1.month.ago..Time.current).count,
      
      # その他の統計
      total_gift_people: GiftPerson.count,
      total_favorites: Favorite.count,
      total_reminds: Remind.count
    }
  end

  # 最近の活動情報を構築
  def build_recent_activities
    {
      # 最近登録されたユーザー（直近5人）
      recent_users: User.order(created_at: :desc).limit(5),
      
      # 最近作成されたギフト記録（直近10件）
      recent_gift_records: GiftRecord.includes(:user, :gift_person)
                                   .order(created_at: :desc)
                                   .limit(10),
      
      # 最近投稿されたコメント（直近10件）
      recent_comments: Comment.includes(:user, :gift_record)
                             .order(created_at: :desc)
                             .limit(10)
    }
  end

  # 管理者向けアラート情報を構築
  def build_admin_alerts
    alerts = []
    
    # 今日作成されたコンテンツ数をチェック
    today_gift_records = GiftRecord.where(created_at: Date.current.all_day).count
    today_comments = Comment.where(created_at: Date.current.all_day).count
    
    if today_gift_records > 50  # 閾値は調整可能
      alerts << {
        type: 'warning',
        message: "本日のギフト記録投稿数が多くなっています（#{today_gift_records}件）",
        action_text: "ギフト記録を確認",
        action_path: admin_gift_records_path
      }
    end
    
    if today_comments > 100  # 閾値は調整可能
      alerts << {
        type: 'warning', 
        message: "本日のコメント投稿数が多くなっています（#{today_comments}件）",
        action_text: "コメントを確認",
        action_path: admin_comments_path
      }
    end
    
    # 管理者権限のないアクセス試行があった場合（ログから検出）
    # 実装はより詳細なログ機能が必要
    
    alerts
  end
end