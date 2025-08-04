class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    basic_action
  end

  private
  def basic_action
    @omniauth = request.env["omniauth.auth"]
    if @omniauth.present?
      @profile = User.find_or_initialize_by(provider: @omniauth["provider"], uid: @omniauth["uid"])
      
      # 新規ユーザーまたは既存ユーザーの情報を更新
      if @profile.new_record?
        # 新規ユーザーの場合
        email = @omniauth["info"]["email"] || ""
        @profile.assign_attributes(
          email: email,
          name: @omniauth["info"]["name"],
          password: Devise.friendly_token[0, 20]
        )
        @profile.save!
      elsif @profile.email.blank? && @omniauth["info"]["email"].present?
        # 既存ユーザーでemailが空の場合、emailを更新
        @profile.update!(email: @omniauth["info"]["email"])
      end
      
      @profile.set_values(@omniauth)
      sign_in(:user, @profile)
    end
    # ログイン後のflash messageとリダイレクト先を設定
    flash[:notice] = "ログインしました"
    redirect_to mypage_path
  end

  def fake_email(uid, provider)
    "#{auth.uid}-#{auth.provider}@example.com"
  end
end
