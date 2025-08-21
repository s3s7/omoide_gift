# 管理者用システム統計コントローラー
class Admin::StatisticsController < Admin::BaseController

  def index
    @statistics = build_detailed_statistics
    log_admin_action("システム統計表示")
  end

  private

  def build_detailed_statistics
    {
      users: build_user_statistics,
      gift_records: build_gift_record_statistics,
      comments: build_comment_statistics,
      activity: build_activity_statistics
    }
  end

  def build_user_statistics
    {
      total: User.count,
      admins: User.admin.count,
      general: User.general.count,
      line_users: User.where.not(provider: nil).count,
      email_users: User.where(provider: nil).count,
      monthly_registrations: (1..12).map do |month|
        User.where(created_at: Date.new(Date.current.year, month).all_month).count
      end
    }
  end

  def build_gift_record_statistics
    {
      total: GiftRecord.count,
      public: GiftRecord.where(is_public: true).count,
      private: GiftRecord.where(is_public: false).count,
      with_images: GiftRecord.joins(:images_attachments).distinct.count,
      monthly_posts: (1..12).map do |month|
        GiftRecord.where(created_at: Date.new(Date.current.year, month).all_month).count
      end
    }
  end

  def build_comment_statistics
    {
      total: Comment.count,
      monthly_comments: (1..12).map do |month|
        Comment.where(created_at: Date.new(Date.current.year, month).all_month).count
      end
    }
  end

  def build_activity_statistics
    {
      favorites: Favorite.count,
      reminds: Remind.count,
      gift_people: GiftPerson.count
    }
  end
end