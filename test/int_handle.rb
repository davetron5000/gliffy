require 'gliffy/credentials'
require 'gliffy/handle'
require 'integration_testbase.rb'
require 'it_cred.rb'

include Gliffy

class INT_testHandle < IntegrationTestBase
  def setup
    super
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

  def test_error
    assert_raises RequestFailedException do
      @handle.folder_delete('ROOT/some/path/that/is/not/here')
    end
  end

  def test_account_meta_data
    [true,false].each do |show_users|
      account = @handle.account_get(show_users)
      assert_equal($account_id,account.account_id,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal(@account_name,account.name,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal(@account_max_users,account.max_users,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal(@account_type,account.account_type,show_users ? "Showing Users" : "Not Showing Users")
      if show_users
        assert_equal(1,account.users.size)
        assert_equal($username,account.users[0].username)
      else
        assert_nil(account.users)
      end
    end
  end
end
