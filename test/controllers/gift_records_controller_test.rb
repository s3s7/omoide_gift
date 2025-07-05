require "test_helper"

class GiftRecordsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get gift_records_index_url
    assert_response :success
  end
end
