class GiftRecordsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

   def new
    @gift_record = GiftRecord.new
    @gift_people = current_user.gift_people
  end

  def create
    # 新しいギフト相手を作成する場合
    if params[:gift_record][:gift_people_id] == "new" && params[:gift_person].present?
      # まずギフト相手を作成（gift_record_idなしで）
      @gift_person = current_user.gift_people.build(gift_person_params)
      @gift_person.gift_record_id = nil  # 一時的にnilに設定
      
      if @gift_person.save
        @gift_record = current_user.gift_records.build(gift_record_params.except(:gift_people_id))
        @gift_record.gift_people = @gift_person
        
        if @gift_record.save
          # gift_recordが保存されたらgift_personにgift_record_idを設定
          @gift_person.update(gift_record_id: @gift_record.id)
          redirect_to gift_records_path, success: t("defaults.flash_message.created", item: GiftRecord.model_name.human)
          return
        end
      else
        @gift_people = current_user.gift_people
        flash.now[:danger] = "ギフト相手の作成に失敗しました。"
        render :new, status: :unprocessable_entity
        return
      end
    else
      @gift_record = current_user.gift_records.build(gift_record_params)
      if @gift_record.save
        redirect_to gift_records_path, success: t("defaults.flash_message.created", item: GiftRecord.model_name.human)
        return
      end
    end
    
    @gift_people = current_user.gift_people
    flash.now[:danger] = t("defaults.flash_message.not_created", item: GiftRecord.model_name.human)
    render :new, status: :unprocessable_entity
  end

  def show
    @gift_record = GiftRecord.find(params[:id])
    @comment = Comment.new
    @comments = @gift_record.comments.includes(:user).order(created_at: :desc)
  end

  def edit
    @gift_record = current_user.gift_records.find(params[:id])
  end

  private

  def gift_record_params
    params.require(:gift_record).permit(:title, :description, :body, :gift_record_image, :gift_record_image_cache, :gift_people_id, :memo, :item_name, :amount, :gift_at)
  end

  def gift_person_params
    params.require(:gift_person).permit(:name, :relationship_id, :birthday, :likes, :dislikes, :memo)
  end
end
