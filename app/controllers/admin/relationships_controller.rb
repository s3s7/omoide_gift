# 管理者用関係性管理コントローラー
class Admin::RelationshipsController < Admin::BaseController
  before_action :set_relationship, only: [ :edit, :update, :destroy, :move_up, :move_down ]

  def index
    @relationships = Relationship.ordered.page(params[:page]).per(per_page)
    log_admin_action("関係性一覧表示")
  end

  def new
    @relationship = Relationship.new
  end

  def create
    @relationship = Relationship.new(relationship_params)
    if @relationship.save
      admin_flash_success("関係性を作成しました。")
      log_admin_action("関係性作成", "Relationship", @relationship.id)
      redirect_to admin_relationships_path
    else
      admin_flash_error("関係性の作成に失敗しました。")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    log_admin_action("関係性編集画面表示", "Relationship", @relationship.id)
  end

  def update
    if @relationship.update(relationship_params)
      admin_flash_success("関係性を更新しました。")
      log_admin_action("関係性更新", "Relationship", @relationship.id)
      redirect_to admin_relationships_path
    else
      admin_flash_error("関係性の更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @relationship.gift_people.exists?
      admin_flash_error("この関係性を使用しているギフト相手があるため削除できません。")
    elsif @relationship.destroy
      admin_flash_success("関係性を削除しました。")
      log_admin_action("関係性削除", "Relationship", @relationship.id, @relationship.name)
    else
      admin_flash_error("関係性の削除に失敗しました。")
    end
    redirect_to admin_relationships_path
  end

  def move_up
    if @relationship.move_up!
      admin_flash_success("「#{@relationship.name}」の順序を上に移動しました。")
      log_admin_action("関係性順序変更（上）", "Relationship", @relationship.id)
    else
      admin_flash_error("順序の変更に失敗しました。")
    end
    redirect_to admin_relationships_path
  end

  def move_down
    if @relationship.move_down!
      admin_flash_success("「#{@relationship.name}」の順序を下に移動しました。")
      log_admin_action("関係性順序変更（下）", "Relationship", @relationship.id)
    else
      admin_flash_error("順序の変更に失敗しました。")
    end
    redirect_to admin_relationships_path
  end

  private

  def set_relationship
    @relationship = Relationship.find(params[:id])
  end

  def relationship_params
    params.require(:relationship).permit(:name)
  end
end
