# 管理者用ギフトアイテムカテゴリ管理コントローラー
class Admin::GiftItemCategoriesController < Admin::BaseController
  before_action :set_gift_item_category, only: [ :edit, :update, :destroy, :move_up, :move_down ]

  def index
    @gift_item_categories = GiftItemCategory.ordered.page(params[:page]).per(per_page)
    log_admin_action("ギフトカテゴリ一覧表示")
  end

  def new
    @gift_item_category = GiftItemCategory.new
  end

  def create
    @gift_item_category = GiftItemCategory.new(gift_item_category_params)
    if @gift_item_category.save
      admin_flash_success("ギフトカテゴリを作成しました。")
      log_admin_action("ギフトカテゴリ作成", "GiftItemCategory", @gift_item_category.id)
      redirect_to admin_gift_item_categories_path
    else
      admin_flash_error("ギフトカテゴリの作成に失敗しました。")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    log_admin_action("ギフトカテゴリ編集画面表示", "GiftItemCategory", @gift_item_category.id)
  end

  def update
    if @gift_item_category.update(gift_item_category_params)
      admin_flash_success("ギフトカテゴリを更新しました。")
      log_admin_action("ギフトカテゴリ更新", "GiftItemCategory", @gift_item_category.id)
      redirect_to admin_gift_item_categories_path
    else
      admin_flash_error("ギフトカテゴリの更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @gift_item_category.gift_records.exists?
      admin_flash_error("このカテゴリを使用しているギフト記録があるため削除できません。")
    elsif @gift_item_category.destroy
      admin_flash_success("ギフトカテゴリを削除しました。")
      log_admin_action("ギフトカテゴリ削除", "GiftItemCategory", @gift_item_category.id, @gift_item_category.name)
    else
      admin_flash_error("ギフトカテゴリの削除に失敗しました。")
    end
    redirect_to admin_gift_item_categories_path
  end

  def move_up
    if @gift_item_category.move_up!
      admin_flash_success("「#{@gift_item_category.name}」の順序を上に移動しました。")
      log_admin_action("ギフトカテゴリ順序変更（上）", "GiftItemCategory", @gift_item_category.id)
    else
      admin_flash_error("順序の変更に失敗しました。")
    end
    redirect_to admin_gift_item_categories_path
  end

  def move_down
    if @gift_item_category.move_down!
      admin_flash_success("「#{@gift_item_category.name}」の順序を下に移動しました。")
      log_admin_action("ギフトカテゴリ順序変更（下）", "GiftItemCategory", @gift_item_category.id)
    else
      admin_flash_error("順序の変更に失敗しました。")
    end
    redirect_to admin_gift_item_categories_path
  end

  private

  def set_gift_item_category
    @gift_item_category = GiftItemCategory.find(params[:id])
  end

  def gift_item_category_params
    params.require(:gift_item_category).permit(:name)
  end
end
