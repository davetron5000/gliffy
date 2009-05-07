require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'testbase'
require 'gliffy/credentials'

class HTTPartyAuth
  def initialize(auth)
    @auth = auth
  end

  def post(url)
    HTTParty.post(url,:basic_auth => @auth)
  end
end

include Gliffy

class IntegrationTestBase < Test::Unit::TestCase

  def setup
    @account_name = 'TEST'
    @account_type = 'Premium'
    @account_max_users = 10
    @account_id = $account_id
    @username = $username
    @oauth_consumer_key = $oauth_consumer_key
    @oauth_consumer_secret = $oauth_consumer_secret
    @cred = Credentials.new(@oauth_consumer_key,
                            @oauth_consumer_secret,
                            'Ruby Client - Integration Tests',
                            @account_id,
                            @username)
    @api_root = $api_root
    @basic_auth = {:username => $http_auth_username, :password => $http_auth_password}

  end

  def test_true
    assert true
  end
end
