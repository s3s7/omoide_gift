# 管理者用コメント管理コントローラー
# コメントの閲覧、編集、削除を提供
class Admin::CommentsController < Admin::BaseController
  before_action :set_comment, only: [ :show, :edit, :update, :destroy ]

  def index
    @comments = filter_and_sort_comments
    @total_count = Comment.count
    @today_count = Comment.where(created_at: Date.current.all_day).count

    log_admin_action("コメント一覧表示", "Comment", "検索条件: #{search_params.to_h}")
  end

  def show
    log_admin_action("コメント詳細表示", "Comment", @comment.id)
  end

  def edit
    log_admin_action("コメント編集画面表示", "Comment", @comment.id)
  end

  def update
    if @comment.update(comment_params)
      admin_flash_success("コメントを更新しました。")
      log_admin_action("コメント更新", "Comment", @comment.id)
      redirect_to admin_comment_path(@comment)
    else
      admin_flash_error("コメントの更新に失敗しました。")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    comment_info = "ID: #{@comment.id}, 投稿者: #{@comment.user.name}, 内容: #{@comment.excerpt(50)}"

    if @comment.destroy
      admin_flash_success("コメントを削除しました。")
      log_admin_action("コメント削除", "Comment", @comment.id, comment_info)
      redirect_to admin_comments_path
    else
      admin_flash_error("コメントの削除に失敗しました。")
      redirect_to admin_comment_path(@comment)
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    admin_flash_error("指定されたコメントが見つかりません。")
    redirect_to admin_comments_path
  end

  # コメントのフィルタリングとソート
  def filter_and_sort_comments
    base = Comment.includes(:user, :gift_record)

    q_params = {}
    q_params[:body_or_user_name_cont] = params[:search] if params[:search].present?
    q_params[:user_id_eq] = params[:user_id] if params[:user_id].present?
    q_params[:created_at_gteq] = Date.parse(params[:date_from]) if params[:date_from].present?
    q_params[:created_at_lteq] = Date.parse(params[:date_to]) if params[:date_to].present?

    @q = base.ransack(q_params)
    comments = @q.result(distinct: true)

    # ソート
    case params[:sort]
    when "body"
      comments = comments.order(body: sort_direction)
    when "user_name"
      comments = comments.joins(:user).order("users.name #{sort_direction}")
    else
      comments = comments.order(created_at: sort_direction)
    end

    # ページネーション
    comments.page(params[:page]).per(per_page)
  end

  # ソート方向の決定
  def sort_direction
    params[:direction] == "asc" ? :asc : :desc
  end

  # ストロングパラメータ
  def comment_params
    params.require(:comment).permit(:body)
  end
end
