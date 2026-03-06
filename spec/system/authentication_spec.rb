require "rails_helper"

RSpec.describe "Authentication", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:rack_test)
  end

  it "logs in with valid credentials" do
    visit new_user_session_path

    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: user.password
    click_button "ログイン"

    expect(page).to have_current_path(root_path, ignore_query: true)
    expect(page).to have_content("ログアウト")
  end
end
