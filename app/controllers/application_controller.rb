class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # CSRFトークン検証を有効化（セキュリティ強化）
  protect_from_forgery with: :exception

  # Deviseのストロングパラメータ設定
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Deviseのコールバックメソッドをオーバーライド

  # ログイン後のリダイレクト先を設定
  def after_sign_in_path_for(resource)
    # カスタムメッセージは既にDeviseの設定で表示されるため、ここではリダイレクト先のみ設定
    stored_location_for(resource) || root_path
  end

  # ログアウト後のリダイレクト先を設定
  def after_sign_out_path_for(resource_or_scope)
    # カスタムメッセージは既にDeviseの設定で表示されるため、ここではリダイレクト先のみ設定
    root_path
  end

  private

  # 共通のflashメッセージ設定メソッド
  def set_flash_message(type, key, options = {})
    message = I18n.t("defaults.flash_message.#{key}", **options.merge(default: options[:message] || key.to_s))
    flash[type] = message
  end

  # 成功メッセージの設定
  def flash_success(key, options = {})
    set_flash_message(:notice, key, options)
  end

  # エラーメッセージの設定
  def flash_error(key, options = {})
    set_flash_message(:alert, key, options)
  end

  # 警告メッセージの設定
  def flash_warning(key, options = {})
    set_flash_message(:warning, key, options)
  end

  # 情報メッセージの設定
  def flash_info(key, options = {})
    set_flash_message(:info, key, options)
  end

  # Deviseのストロングパラメータ設定
  def configure_permitted_parameters
    # 新規登録時にnameパラメータを許可
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    # アカウント更新時にnameパラメータを許可
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
