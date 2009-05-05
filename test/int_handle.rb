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
    @handle = Gliffy::Handle.new(@api_root,@cred,HTTPartyAuth.new(@basic_auth))
  end

  def test_init
    assert_equal(AccessToken,@handle.token.class,@handle.token.inspect)
  end

  def test_delete_token
    account = @handle.account_get
    assert_equal($account_id,account.account_id)
    token = @cred.access_token.token
    @handle.delete_token
    account = @handle.account_get
    assert_equal($account_id,account.account_id)
    assert(@cred.access_token.token != token,"Expected to get a token different than what we started with: #{token}")
  end

  #def test_create_test_account
  #  10.times { puts '======' }
  #  response = @handle.anything(:create,'accounts.xml',{ :accountName => 'Ruby Client Test Account', :accountType => 'Test' },true)
  #  puts response.inspect
  #end

  def test_account_meta_data
    [true,false].each do |show_users|
      account = @handle.account_get(show_users)
      assert_equal($account_id,account.account_id,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal('Ruby Client Test Account',account.name,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal(nil,account.max_users,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal('Basic',account.account_type,show_users ? "Showing Users" : "Not Showing Users")
      if show_users
        assert_equal(1,account.users.size)
        assert_equal($username,account.users[0].username)
      else
        assert_nil(account.users)
      end
    end
  end
end
