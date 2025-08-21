# 管理者認可機能を提供するConcern
# 管理者限定のコントローラーやアクションで使用
module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    # 管理者認証を行うbefore_action
    before_action :authenticate_admin!, unless: :devise_controller?
  end

  private

  # 管理者認証チェック
  # ログインユーザーが管理者でない場合はアクセス拒否
  def authenticate_admin!
    # まずユーザーがログインしているかチェック
    authenticate_user!
    
    # 管理者権限チェック
    unless current_user&.admin?
      handle_admin_access_denied
    end
  end

  # 管理者権限チェック（リダイレクトなし）
  # 条件分岐で使用する場合
  def admin_user?
    user_signed_in? && current_user.admin?
  end

  # 管理者アクセス拒否時の処理
  def handle_admin_access_denied
    Rails.logger.warn "管理者権限なしでのアクセス試行: User ID: #{current_user&.id}, IP: #{request.remote_ip}, Path: #{request.fullpath}"
    
    # フラッシュメッセージを設定
    flash[:alert] = "このページにアクセスする権限がありません。"
    
    # 一般ユーザー用ページにリダイレクト
    redirect_to root_path
  end

  # 管理者ログとして記録
  def log_admin_action(action_name, target_model = nil, target_id = nil)
    log_message = "管理者アクション: #{action_name}"
    log_message += " - 対象: #{target_model}##{target_id}" if target_model && target_id
    log_message += " - 実行者: User##{current_user.id}"
    
    Rails.logger.info log_message
  end
end