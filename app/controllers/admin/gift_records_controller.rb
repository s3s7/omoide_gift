# 管理者用ギフト記録管理コントローラー
# ギフト記録の閲覧、編集、削除、公開設定管理を提供
class Admin::GiftRecordsController < Admin::BaseController
  before_action :set_gift_record, only: [ :show, :edit, :update, :destroy, :toggle_public ]

  def index
    @gift_records = filter_and_sort_gift_records
    @total_count = GiftRecord.count
    @public_count = GiftRecord.where(is_public: true).count
    @private_count = GiftRecord.where(is_public: false).count

    log_admin_action("ギフト記録一覧表示", "GiftRecord", "検索条件: #{search_params.to_h}")
  end

  def show
    @record_statistics = build_record_statistics(@gift_record)
    log_admin_action("ギフト記録詳細表示", "GiftRecord", @gift_record.id)
  end

  def edit
    log_admin_action("ギフト記録編集画面表示", "GiftRecord", @gift_record.id)
  end

  def update
    if @gift_record.update(gift_record_params)
      admin_flash_success("ギフト記録を更新しました。")
      log_admin_action("ギフト記録更新", "GiftRecord", @gift_record.id)
      redirect_to admin_gift_record_path(@gift_record)
    else
      admin_flash_error("ギフト記録の更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    record_info = "ID: #{@gift_record.id}, アイテム: #{@gift_record.display_item_name}, 所有者: #{@gift_record.user.name}"

    if @gift_record.destroy
      admin_flash_success("ギフト記録を削除しました。")
      log_admin_action("ギフト記録削除", "GiftRecord", @gift_record.id, record_info)
      redirect_to admin_gift_records_path
    else
      admin_flash_error("ギフト記録の削除に失敗しました。")
      redirect_to admin_gift_record_path(@gift_record)
    end
  end

  # 公開/非公開の切り替え
  def toggle_public
    old_status = @gift_record.is_public? ? "公開" : "非公開"
    new_status = @gift_record.is_public? ? "非公開" : "公開"

    if @gift_record.update(is_public: !@gift_record.is_public?)
      admin_flash_success("「#{@gift_record.display_item_name}」を#{new_status}に変更しました。")
      log_admin_action("ギフト記録公開設定変更", "GiftRecord", @gift_record.id, "#{old_status} → #{new_status}")
    else
      admin_flash_error("公開設定の変更に失敗しました。")
    end

    redirect_to admin_gift_record_path(@gift_record)
  end

  private

  def set_gift_record
    @gift_record = GiftRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    admin_flash_error("指定されたギフト記録が見つかりません。")
    redirect_to admin_gift_records_path
  end

  # ギフト記録のフィルタリングとソート
  def filter_and_sort_gift_records
    records = GiftRecord.includes(:user, :gift_person, :event, :gift_item_category)

    # 検索フィルタ
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      records = records.joins(:user, :gift_person)
                      .where("gift_records.item_name ILIKE ? OR users.name ILIKE ? OR gift_people.name ILIKE ?",
                             search_term, search_term, search_term)
    end

    # 公開設定フィルタ
    case params[:is_public]
    when "true"
      records = records.where(is_public: true)
    when "false"
      records = records.where(is_public: false)
    end

    # ギフト分類フィルタ
    case params[:gift_direction]
    when "received"
      records = records.where(gift_direction: :received)
    when "given"
      records = records.where(gift_direction: :given)
    end

    # ユーザーフィルタ
    if params[:user_id].present?
      records = records.where(user_id: params[:user_id])
    end

    # 日付範囲フィルタ
    if params[:date_from].present?
      records = records.where("gift_at >= ?", Date.parse(params[:date_from]))
    end
    if params[:date_to].present?
      records = records.where("gift_at <= ?", Date.parse(params[:date_to]))
    end

    # ソート
    case params[:sort]
    when "item_name"
      records = records.order(item_name: sort_direction)
    when "gift_at"
      records = records.order(gift_at: sort_direction)
    when "user_name"
      records = records.joins(:user).order("users.name #{sort_direction}")
    when "is_public"
      records = records.order(is_public: sort_direction)
    else
      records = records.order(created_at: sort_direction)
    end

    # ページネーション
    records.page(params[:page]).per(per_page)
  end

  # ソート方向の決定
  def sort_direction
    params[:direction] == "asc" ? :asc : :desc
  end

  # ギフト記録統計情報の構築
  def build_record_statistics(record)
    {
      comments_count: record.comments.count,
      favorites_count: record.favorites.count,
      images_count: record.images_count,
      recent_comments: record.comments.includes(:user).order(created_at: :desc).limit(5)
    }
  end

  # ストロングパラメータ
  def gift_record_params
    params.require(:gift_record).permit(
      :item_name, :memo, :is_public, :commentable, :gift_direction,
      :amount, :gift_at, :event_id, :gift_item_category_id,
      images: [], delete_image_ids: []
    )
  end
end
