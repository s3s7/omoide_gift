# 管理者用ギフト相手管理コントローラー
class Admin::GiftPeopleController < Admin::BaseController
  before_action :set_gift_person, only: [ :show, :edit, :update, :destroy ]

  def index
    @gift_people = filter_and_sort_gift_people
    log_admin_action("ギフト相手一覧表示", "GiftPerson", "検索条件: #{search_params.to_h}")
  end

  def show
    @person_statistics = build_person_statistics(@gift_person)
    log_admin_action("ギフト相手詳細表示", "GiftPerson", @gift_person.id)
  end

  def edit
    log_admin_action("ギフト相手編集画面表示", "GiftPerson", @gift_person.id)
  end

  def update
    if @gift_person.update(gift_person_params)
      admin_flash_success("ギフト相手情報を更新しました。")
      redirect_to admin_gift_person_path(@gift_person)
    else
      admin_flash_error("ギフト相手情報の更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @gift_person.destroy
      admin_flash_success("ギフト相手を削除しました。")
      redirect_to admin_gift_people_path
    else
      admin_flash_error("ギフト相手の削除に失敗しました。")
      redirect_to admin_gift_person_path(@gift_person)
    end
  end

  private

  def set_gift_person
    @gift_person = GiftPerson.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    admin_flash_error("指定されたギフト相手が見つかりません。")
    redirect_to admin_gift_people_path
  end

  def filter_and_sort_gift_people
    base = GiftPerson.includes(:user, :relationship)

    q_params = {}
    q_params[:name_cont] = params[:search] if params[:search].present?

    @q = base.ransack(q_params)
    @q.result(distinct: true)
      .order(created_at: :desc)
      .page(params[:page]).per(per_page)
  end

  # ギフト相手の統計情報構築
  def build_person_statistics(person)
    {
      gift_records_count: person.gift_records.count,
      public_gift_records_count: person.gift_records.where(is_public: true).count,
      recent_gift_records: person.gift_records.includes(:user, :gift_item_category, :event)
                                 .order(gift_at: :desc, created_at: :desc)
                                 .limit(5),
      latest_gift_at: person.gift_records.maximum(:gift_at) || person.gift_records.maximum(:created_at),
      total_favorites_count: person.gift_records.joins(:favorites).count,
      total_comments_count: person.gift_records.joins(:comments).count
    }
  end

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :address, :memo, :avatar)
  end
end
