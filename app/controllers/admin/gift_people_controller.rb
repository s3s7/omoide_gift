# 管理者用ギフト相手管理コントローラー
class Admin::GiftPeopleController < Admin::BaseController
  before_action :set_gift_person, only: [:show, :edit, :update, :destroy]

  def index
    @gift_people = filter_and_sort_gift_people
    log_admin_action("ギフト相手一覧表示", "GiftPerson", "検索条件: #{search_params.to_h}")
  end

  def show
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
    people = GiftPerson.includes(:user, :relationship)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      people = people.where("name ILIKE ?", search_term)
    end

    people.order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id)
  end
end