# 管理者機能の基底コントローラー
# Admin名前空間下のすべてのコントローラーはこのクラスを継承
class Admin::BaseController < ApplicationController
  # 管理者認可機能をインクルード
  include AdminAuthorization

  # 管理者専用レイアウトを使用
  layout "admin"

  # 管理者アクションのログ記録
  before_action :log_admin_access

  protected

  # 管理者アクションの共通ログ記録
  def log_admin_access
    Rails.logger.info "管理者アクセス: #{controller_name}##{action_name} - User: #{current_user.id} (#{current_user.name}) - IP: #{request.remote_ip}"
  end

  # 管理者用フラッシュメッセージのカスタマイズ
  def admin_flash_success(message)
    flash[:notice] = "✅ #{message}"
  end

  def admin_flash_error(message)
    flash[:alert] = "❌ #{message}"
  end

  def admin_flash_warning(message)
    flash[:warning] = "⚠️ #{message}"
  end

  # ページネーション用の1ページあたりの件数設定
  def per_page
    params[:per_page]&.to_i&.clamp(10, 100) || 25
  end

  # 管理者用の検索パラメータ処理
  def search_params
    params.permit(:search, :sort, :direction, :per_page, :page)
  end
end
