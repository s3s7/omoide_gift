class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gift_record, only: [:toggle]

  # AJAX対応のハートボタンToggle機能
  def toggle
    result = Favorite.toggle_favorite(current_user, @gift_record)
    
    respond_to do |format|
      format.json do
        if result[:success]
          render json: {
            success: true,
            favorited: result[:favorited],
            favorites_count: Favorite.favorites_count_for_gift_record(@gift_record),
            action: result[:action]
          }
        else
          render json: {
            success: false,
            error: result[:error] || format_errors(result[:errors]),
            favorited: Favorite.favorited_by_user?(current_user, @gift_record)
          }, status: :unprocessable_entity
        end
      end
      
      format.html do
        if result[:success]
          flash[:notice] = result[:action] == :added ? "お気に入りに追加しました" : "お気に入りから削除しました"
        else
          flash[:alert] = result[:error] || format_errors(result[:errors])
        end
        redirect_back(fallback_location: gift_records_path)
      end
    end
  rescue StandardError => e
    Rails.logger.error "Favorite toggle error: #{e.message}"
    
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          error: "エラーが発生しました",
          favorited: Favorite.favorited_by_user?(current_user, @gift_record)
        }, status: :internal_server_error
      end
      
      format.html do
        flash[:alert] = "エラーが発生しました"
        redirect_back(fallback_location: gift_records_path)
      end
    end
  end

  # お気に入り一覧
  def index
    @favorites = current_user.favorites
      .includes(gift_record: [:gift_person, :event, :user, { gift_person: :relationship }])
      .recent
    
    # アクセス可能な記録のみ表示
    @favorites = @favorites.select do |favorite| 
      gift_record = favorite.gift_record
      gift_record.present? && 
      (gift_record.user_id == current_user.id || gift_record.is_public?)
    end
  end

  private

  def set_gift_record
    @gift_record = GiftRecord.find(params[:id])
    
    # アクセス権限チェック
    unless @gift_record.is_public? || @gift_record.user_id == current_user.id
      respond_to do |format|
        format.json { render json: { success: false, error: "アクセス権限がありません" }, status: :forbidden }
        format.html { redirect_to gift_records_path, alert: "アクセス権限がありません" }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: "記録が見つかりません" }, status: :not_found }
      format.html { redirect_to gift_records_path, alert: "記録が見つかりません" }
    end
  end

  def format_errors(errors)
    return "エラーが発生しました" unless errors.respond_to?(:full_messages)
    errors.full_messages.join(", ")
  end
end