require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "signing in with valid credentials redirects to the app" do
    post session_url, params: { email_address: users(:alice).email_address, password: "password" }

    assert_redirected_to root_url

    get root_url
    assert_response :success
  end

  test "signing in with a wrong password shows an alert" do
    post session_url, params: { email_address: users(:alice).email_address, password: "wrong" }

    assert_redirected_to new_session_url
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "signing out ends the session" do
    sign_in_as users(:alice)

    delete session_url

    assert_redirected_to new_session_url

    get root_url
    assert_redirected_to new_session_url
  end

  test "guests are redirected to sign in" do
    get root_url

    assert_redirected_to new_session_url
  end
end
