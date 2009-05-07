require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'testbase'
require 'gliffy/credentials'
require 'test/it_cred'
require 'test/functest_cred'

class HTTPartyAuth
  def initialize(auth)
    @auth = auth
  end

  def post(url)
    HTTParty.post(url,:basic_auth => @auth)
  end
end

include Gliffy

class FunctionalTestBase < Test::Unit::TestCase

  def setup
    @account_name = 'Ruby Client Integration Test Account'
    @account_type = 'Basic'
    @account_max_users = nil
    @account_id = $functest_account_id
    @username = $username
    @oauth_consumer_key = $functest_oauth_consumer_key
    @oauth_consumer_secret = $functest_oauth_consumer_secret
    @cred = Credentials.new(@oauth_consumer_key,
                            @oauth_consumer_secret,
                            'Ruby Client - Functional Tests',
                            @account_id,
                            @username)
    @api_root = $api_root
    @basic_auth = {:username => $http_auth_username, :password => $http_auth_password}
    @handle = Gliffy::Handle.new(@api_root,@cred,HTTPartyAuth.new(@basic_auth))
  end

  def test_true
    assert true
  end
end
