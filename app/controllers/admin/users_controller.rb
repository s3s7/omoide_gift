# 管理者用ユーザー管理コントローラー
# ユーザーの一覧表示、詳細確認、権限管理を提供
class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :toggle_role, :toggle_status]

  def index
    @users = filter_and_sort_users
    @total_count = User.count
    @admin_count = User.admin.count
    @general_count = User.general.count

    log_admin_action("ユーザー一覧表示", "User", "検索条件: #{search_params.to_h}")
  end

  def show
    @user_statistics = build_user_statistics(@user)
    log_admin_action("ユーザー詳細表示", "User", @user.id)
  end

  def edit
    log_admin_action("ユーザー編集画面表示", "User", @user.id)
  end

  def update
    if @user.update(user_params)
      admin_flash_success("ユーザー情報を更新しました。")
      log_admin_action("ユーザー情報更新", "User", @user.id)
      redirect_to admin_user_path(@user)
    else
      admin_flash_error("ユーザー情報の更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  # 管理者権限の切り替え
  def toggle_role
    # 自分自身の権限変更を防ぐ
    if @user == current_user
      admin_flash_error("自分自身の権限は変更できません。")
      redirect_to admin_user_path(@user)
      return
    end

    old_role = @user.role
    new_role = @user.admin? ? 'general' : 'admin'
    
    if @user.update(role: new_role)
      admin_flash_success("#{@user.name}さんの権限を「#{User.human_attribute_name("role.#{new_role}")}」に変更しました。")
      log_admin_action("ユーザー権限変更", "User", @user.id, "#{old_role} → #{new_role}")
    else
      admin_flash_error("権限の変更に失敗しました。")
    end
    
    redirect_to admin_user_path(@user)
  end

  # アカウント状態の切り替え（将来的な拡張用）
  def toggle_status
    # 現在は実装しないが、将来的にアカウント停止機能を追加する場合のプレースホルダー
    admin_flash_warning("この機能は現在実装されていません。")
    redirect_to admin_user_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    admin_flash_error("指定されたユーザーが見つかりません。")
    redirect_to admin_users_path
  end

  # ユーザーのフィルタリングとソート
  def filter_and_sort_users
    users = User.all

    # 検索フィルタ
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      users = users.where("name ILIKE ? OR email ILIKE ?", search_term, search_term)
    end

    # ロールフィルタ
    if params[:role].present? && User.roles.key?(params[:role])
      users = users.where(role: params[:role])
    end

    # 登録方法フィルタ（LINE登録 vs 通常登録）
    case params[:provider]
    when 'line'
      users = users.where.not(provider: nil)
    when 'email'
      users = users.where(provider: nil)
    end

    # ソート
    case params[:sort]
    when 'name'
      users = users.order(name: sort_direction)
    when 'email'
      users = users.order(email: sort_direction)
    when 'role'
      users = users.order(role: sort_direction)
    when 'gift_records_count'
      users = users.left_joins(:gift_records)
                  .group(:id)
                  .order("COUNT(gift_records.id) #{sort_direction}")
    else
      users = users.order(created_at: sort_direction)
    end

    # ページネーション
    users.page(params[:page]).per(per_page)
  end

  # ソート方向の決定
  def sort_direction
    params[:direction] == 'asc' ? :asc : :desc
  end

  # ユーザー統計情報の構築
  def build_user_statistics(user)
    {
      gift_records_count: user.gift_records.count,
      gift_people_count: user.gift_people.count,
      comments_count: user.comments.count,
      favorites_count: user.favorites.count,
      reminds_count: user.reminds.count,
      public_gift_records_count: user.gift_records.where(is_public: true).count,
      recent_activity: user.gift_records.order(created_at: :desc).limit(5)
    }
  end

  # ストロングパラメータ
  def user_params
    params.require(:user).permit(:name, :email)
  end
end