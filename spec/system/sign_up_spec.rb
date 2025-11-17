require 'rails_helper'

RSpec.describe "ユーザー新規登録", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "有効な情報で新規登録でき、確認メールが送信されること" do
    visit new_user_registration_path

    fill_in "ユーザーネーム", with: "テストユーザー"
    fill_in "メールアドレス", with: "test@example.com"
    fill_in "パスワード(6文字以上)", with: "password"
    fill_in "パスワード(確認用)", with: "password"

    expect {
      click_button "ユーザー登録"
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(page).to have_content("本人確認用のメールを送信しました")

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to include("test@example.com")

    confirmation_url = mail.body.encoded[%r{http[^"]+/users/confirmation\?confirmation_token=[^"]+}]
    expect(confirmation_url).to be_present

    visit confirmation_url

    expect(page).to have_content("メールアドレスが確認できました")
  end

  it "無効な情報では登録できず、エラーメッセージが表示されること" do
    visit new_user_registration_path

    fill_in "ユーザーネーム", with: ""
    fill_in "メールアドレス", with: ""
    fill_in "パスワード(6文字以上)", with: ""
    fill_in "パスワード(確認用)", with: ""

    click_button "ユーザー登録"

    expect(page).to have_content("ユーザーネームを入力してください")
    expect(page).to have_content("を入力してください")
    expect(page).to have_content("は正しい形式で入力してください")
    expect(page).to have_content("パスワードを入力してください")
    expect(page).to have_content("パスワードは6文字以上で入力してください")
    expect(page).to have_content("パスワード（確認用）を入力してください")
  end

  it "パスワード(確認用)が不一致の場合、エラーメッセージが表示されること" do
    visit new_user_registration_path

    fill_in "ユーザーネーム", with: "テストユーザー"
    fill_in "メールアドレス", with: "test@example.com"
    fill_in "パスワード(6文字以上)", with: "password"
    fill_in "パスワード(確認用)", with: ""

    click_button "ユーザー登録"

    expect(page).to have_content("パスワード（確認用）と一致しません")
  end

  it "確認メール再送信リンクから再送信ができること" do
    user = User.create!(
      name: "未確認ユーザー",
      email: "unconfirmed@example.com",
      password: "password",
      password_confirmation: "password",
      confirmed_at: nil
    )

    ActionMailer::Base.deliveries.clear

    visit new_user_session_path
    click_link "認証メールが届いていない方はこちら"

    expect(page).to have_current_path(new_user_confirmation_path)

    fill_in "メールアドレス", with: user.email
    click_button "認証メールを送信する"

    expect(page).to have_content("認証メールを送信しました")

    expect(ActionMailer::Base.deliveries.count).to eq(1)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to include(user.email)
  end
end
