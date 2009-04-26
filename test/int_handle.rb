require 'gliffy/credentials'
require 'gliffy/handle'
require 'integration_testbase.rb'
require 'it_cred.rb'

include Gliffy


class INT_testHandle < IntegrationTestBase
  def setup
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

  def test_init
    handle = Gliffy::Handle.new(@api_root,@cred,HTTPartyAuth.new(@basic_auth))
    assert_equal(AccessToken,handle.token.class,handle.token.inspect)
  end

end
