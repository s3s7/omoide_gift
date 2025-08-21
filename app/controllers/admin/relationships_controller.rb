# 管理者用関係性管理コントローラー
class Admin::RelationshipsController < Admin::BaseController
  before_action :set_relationship, only: [ :edit, :update, :destroy ]

  def index
    @relationships = Relationship.order(:name).page(params[:page]).per(per_page)
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

  private

  def set_relationship
    @relationship = Relationship.find(params[:id])
  end

  def relationship_params
    params.require(:relationship).permit(:name)
  end
end
