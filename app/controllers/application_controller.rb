class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Deviseログアウト後のリダイレクト先を設定
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
  
  # CSRFトークン検証を有効化（セキュリティ強化）
  protect_from_forgery with: :exception
end
