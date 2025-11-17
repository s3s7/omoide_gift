require "rails_helper"

RSpec.describe "ユーザーログイン", type: :system do
  before do
    driven_by :rack_test
  end
  let(:user) { create(:user, email: "test@example.com", password: "password") }

  it "トップページからログインページに遷移し、正しい情報でログインできる" do
    visit root_path
      within("main") do
    click_link "ログイン"
    end

    expect(page).to have_current_path(new_user_session_path)

    fill_in "メールアドレス", with: user.email
    fill_in "パスワード(6文字以上)", with: "password"
    click_button "ログイン"

    expect(page).to have_content("ログインしました")
    expect(page).to have_current_path(root_path)
    expect(page).to have_content(user.name)
  end

  it "ログイン後にログインリンクが消える" do
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード(6文字以上)", with: "password"
    click_button "ログイン"

    expect(page).not_to have_link("ログイン")
    expect(page).to have_link("ログアウト")
  end

  it "ログアウトボタンでログアウトできる", js: true do
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード(6文字以上)", with: "password"
    click_button "ログイン"

    expect(page).to have_content("ログインしました")

    within("main") do
      click_link "ログアウト"
    end

    expect(page).to have_content("ログアウトしました")
    expect(page).to have_link("ログイン")
  end

  it "間違ったメールアドレスではログインできない" do
    visit new_user_session_path
    fill_in "メールアドレス", with: "wrong@example.com"
    fill_in "パスワード(6文字以上)", with: "password"
    click_button "ログイン"

    expect(page).to have_content("ユーザーが見つかりません")
    expect(page).to have_current_path(new_user_session_path)
  end

  # describe "パスワード再設定機能" do
  #   before { ActionMailer::Base.deliveries.clear }

  #   let(:user) { create(:user, email: "test@example.com", password: "password") }
  #   let(:new_password) { "newpassword" }
  #   let(:mail) { ActionMailer::Base.deliveries.last }
  #   let(:reset_link) { mail.body.encoded.match(/href="(?<url>.+?)"/)[:url] }

  #   it "パスワード再設定メールが送信される" do
  #     visit new_user_session_path
  #     click_link "パスワードをお忘れですか？"

  #     expect(page).to have_current_path(new_user_password_path)

  #     fill_in "メールアドレス", with: user.email
  #     click_button "再設定メールを送信する"

  #     expect(page).to have_content("パスワード再設定メールを送信しました")
  #     expect(ActionMailer::Base.deliveries.size).to eq(1)
  #   end

  #   it "メール内のリンクからパスワードを再設定できる" do
  #     visit new_user_password_path
  #     fill_in "メールアドレス", with: user.email
  #     click_button "再設定メールを送信する"

  #     visit reset_link

  #     fill_in "新しいパスワード（6文字以上）", with: new_password
  #     fill_in "新しいパスワード（確認用）", with: new_password
  #     click_button "パスワードを変更する"

  #     expect(page).to have_content("パスワードが正しく変更されました。")
  #   end

  #   it "新しいパスワードでログインできる" do
  #     raw_token, enc_token = Devise.token_generator.generate(User, :reset_password_token)
  #     user.update!(
  #       reset_password_token: enc_token,
  #       reset_password_sent_at: Time.current
  #     )

  #     visit edit_user_password_path(reset_password_token: raw_token)

  #     fill_in "新しいパスワード（6文字以上）", with: "newpassword"
  #     fill_in "新しいパスワード（確認用）", with: "newpassword"
  #     click_button "パスワードを変更する"

  #     click_link "ログアウト", match: :first
  #     expect(page).to have_content("ログアウトしました")

  #     visit new_user_session_path
  #     fill_in "メールアドレス", with: user.email
  #     fill_in "パスワード(6文字以上)", with: "newpassword"
  #     click_button "ログイン"

  #     expect(page).to have_content("ログインしました")
  #     expect(page).to have_content(user.name)
  #   end
  # end
end
