module AuthenticationHelpers
  def sign_in(user)
    token = user.generate_magic_token!
    get verify_session_path(token: token)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
