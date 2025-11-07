RSpec.configure do |config|
  config.before(:each) do
    token_id = "test-token-id"
    payload = {
      iss: "My App",
      iat: Time.current.utc.to_i,
      exp: (Time.current + 2.hours).utc.to_i,
      aud: "some-app-uid",
      jti: token_id,
      sub: 1,
      user: {
        id: 1,
        email: "admin@example.com",
        per: "user_management.read,user_management.write,user_management.delete"
      }
    }.to_json

    allow(REDIS).to receive(:setex).with(/oauth:token:.*/, anything, anything)
    allow(REDIS).to receive(:get).with(/oauth:token:.*/).and_return(payload)
    allow(REDIS).to receive(:del).with(/oauth:token:.*/)
  end
end
