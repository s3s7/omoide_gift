class GiftRecordsController < ApplicationController
  def index
  end

   def new
    @gift_record = GiftRecord.new
  end

  def create
    if @user.present?
     @user.gift_records

      @gift_record = current_user.gift_records.build(gift_record_params)
      if @gift_record.save
        redirect_to gift_records_path, success: t("defaults.flash_message.created", item: GiftRecord.model_name.human)
      else
        flash.now[:danger] = t("defaults.flash_message.not_created", item: GiftRecord.model_name.human)
        render :new, status: :unprocessable_entity
      end

    else
      @gift_record = GiftRecord.new
      flash.now[:danger] = t("defaults.flash_message.not_created", item: GiftRecord.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @gift_record = GiftRecord.find(params[:id])
    @comment = Comment.new
    @comments = @gift_record.comments.includes(:user).order(created_at: :desc)
  end

  def edit
    @gift_record = current_user.gift_records.find(params[:id])
  end
end
