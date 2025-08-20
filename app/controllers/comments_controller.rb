class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gift_record
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :check_comment_owner, only: [ :edit, :update, :destroy ]

  def create
    @comment = @gift_record.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @gift_record, notice: "コメントを投稿しました。" }
        format.json { render json: { success: true, comment: comment_json(@comment) } }
      else
        format.html { redirect_to @gift_record, alert: "コメントの投稿に失敗しました。" }
        format.json { render json: { success: false, errors: @comment.errors.full_messages } }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: { comment: comment_json(@comment) } }
    end
  end

  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to @gift_record, notice: "コメントを更新しました。" }
        format.json { render json: { success: true, comment: comment_json(@comment) } }
      else
        format.html { render :edit }
        format.json { render json: { success: false, errors: @comment.errors.full_messages } }
      end
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to @gift_record, notice: "コメントを削除しました。" }
      format.json { render json: { success: true } }
    end
  end

  private

  def set_gift_record
    @gift_record = current_user.gift_records.find(params[:gift_record_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to gift_records_path, alert: "ギフト記録が見つかりません。"
  end

  def set_comment
    @comment = @gift_record.comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to @gift_record, alert: "コメントが見つかりません。"
  end

  def check_comment_owner
    unless @comment.can_edit_or_delete?(current_user)
      redirect_to @gift_record, alert: "他のユーザーのコメントは編集・削除できません。"
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def comment_json(comment)
    {
      id: comment.id,
      body: comment.body,
      user_name: comment.user.display_name,
      created_at: comment.display_created_at,
      can_edit: comment.can_edit_or_delete?(current_user)
    }
  end
end
