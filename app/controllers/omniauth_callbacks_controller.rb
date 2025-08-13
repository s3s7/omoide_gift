class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    basic_action
  end

  private
  def basic_action
    @omniauth = request.env["omniauth.auth"]
    unless @omniauth.present?
      redirect_to mypage_path, alert: "認証情報を取得できませんでした" and return
    end

    # サインイン済みなら「連携」フロー
    if user_signed_in?
      existing = User.find_by(provider: @omniauth["provider"], uid: @omniauth["uid"])
      if existing && existing.id != current_user.id
        redirect_to mypage_path, alert: "このLINEアカウントは既に他のユーザーに連携されています" and return
      end

      current_user.update!(
        provider: @omniauth["provider"],
        uid: @omniauth["uid"]
      )
      current_user.set_values(@omniauth)

      redirect_to mypage_path, notice: "LINE連携が完了しました" and return
    end

    # 未サインイン時は従来のログイン/新規作成フロー
    @profile = User.find_or_initialize_by(provider: @omniauth["provider"], uid: @omniauth["uid"])

    # 新規ユーザーまたは既存ユーザーの情報を更新
    if @profile.new_record?
      email = @omniauth.dig("info", "email").presence || fake_email(@omniauth["uid"], @omniauth["provider"])
      @profile.assign_attributes(
        email: email,
        name: @omniauth.dig("info", "name"),
        password: Devise.friendly_token[0, 20]
      )
      @profile.save!
    elsif @profile.email.blank? && @omniauth.dig("info", "email").presence
      @profile.update!(email: @omniauth.dig("info", "email"))
    end

    @profile.set_values(@omniauth)
    sign_in(:user, @profile)
    redirect_to mypage_path, notice: "ログインしました"
  end

  def fake_email(uid, provider)
    "#{uid}-#{provider}@example.com"
  end
end
