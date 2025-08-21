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
    comments = Comment.includes(:user, :gift_record)

    # 検索フィルタ
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      comments = comments.joins(:user)
                        .where("comments.body ILIKE ? OR users.name ILIKE ?",
                               search_term, search_term)
    end

    # ユーザーフィルタ
    if params[:user_id].present?
      comments = comments.where(user_id: params[:user_id])
    end

    # 日付範囲フィルタ
    if params[:date_from].present?
      comments = comments.where("comments.created_at >= ?", Date.parse(params[:date_from]))
    end
    if params[:date_to].present?
      comments = comments.where("comments.created_at <= ?", Date.parse(params[:date_to]))
    end

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
