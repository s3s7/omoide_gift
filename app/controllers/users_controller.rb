class UsersController < ApplicationController
  before_action :authenticate_user!, except: [ :new, :create ]
  before_action :set_current_user, only: [ :show, :edit, :update ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path, success: t("users.create.success")
    else
      flash.now[:danger] = t("users.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # マイページ表示
    @total_gift_records = @user.total_gift_records
    @total_gift_amount = @user.total_gift_amount
    @total_gift_people = @user.total_gift_people
    @recent_gift_records = @user.recent_gift_records(5)
    @current_year_stats = @user.current_year_stats
    @public_records_count = @user.public_gift_records_count
    @private_records_count = @user.private_gift_records_count

    # お気に入り統計
    @total_favorites = @user.favorites.count

    # 記念日リマインダー統計
    @total_reminds = @user.reminds.count
    @upcoming_reminds = @user.reminds.unsent.where("notification_at >= ?", Date.current).limit(5)
    @upcoming_reminds_count = @user.reminds.unsent.where("notification_at >= ?", Date.current).count
    @recent_sent_reminds = @user.reminds.sent.order(notification_sent_at: :desc).limit(3)
    # 月別統計（過去6ヶ月）
    @monthly_stats = (0..5).map do |i|
      date = Date.current - i.months
      {
        month: date.strftime("%Y年%m月"),
        count: @user.gift_records.where(
          gift_at: date.beginning_of_month..date.end_of_month
        ).count,
        amount: @user.gift_records.where(
          gift_at: date.beginning_of_month..date.end_of_month
        ).sum(:amount) || 0
      }
    end.reverse
    # 人気のギフト相手 TOP5
    @popular_gift_people = @user.gift_people
      .joins(:gift_records)
      .group("gift_people.id")
      .order("COUNT(gift_records.id) DESC")
      .limit(5)
      .includes(:relationship)
  end

  def edit
    # プロフィール編集
  end

  def update
    # アバター削除の処理
    if params[:user][:remove_avatar] == "1"
      @user.avatar.purge if @user.avatar.attached?
    end
    
    # remove_avatarパラメータを除いてアップデート
    update_params = user_update_params
    update_params.delete(:remove_avatar)
    
    if @user.update(update_params)
      flash_success(:updated, item: "プロフィール")
      redirect_to mypage_path
    else
      flash.now[:alert] = "更新に失敗しました。"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def user_update_params
    params.require(:user).permit(:name, :email, :avatar, :remove_avatar)
  end

  def set_current_user
    @user = current_user
  end

  # ApplicationControllerのヘルパーメソッドを使用
  def flash_success(key, options = {})
    set_flash_message(:notice, key, options)
  end

  def set_flash_message(type, key, options = {})
    message = I18n.t("defaults.flash_message.#{key}", **options.merge(default: options[:message] || key.to_s))
    flash[type] = message
  end
end
