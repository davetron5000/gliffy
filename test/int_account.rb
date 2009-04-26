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

  def test_account_meta_data
    [true,false].each do |show_users|
      account = @handle.account_get(show_users)
      assert_equal($account_id,account.account_id,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal('TEST',account.name,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal(10,account.max_users,show_users ? "Showing Users" : "Not Showing Users")
      assert_equal('Premium',account.account_type,show_users ? "Showing Users" : "Not Showing Users")
      if show_users
        assert_equal(1,account.users.size)
        assert_equal($username,account.users[0].username)
      else
        assert_nil(account.users)
      end
    end
  end

  def test_account_folders
    root_folder = @handle.account_folders
    assert_equal('ROOT',root_folder.name)
    assert_equal(true,root_folder.is_default?)
    assert_equal(0,root_folder.child_folders.size)
  end

  # There are none; not sure if I consider this a bug
  #def test_account_documents
  #  documents = @handle.account_documents
  #end

  # Currently failing, http://jira.gliffy.com/browse/GLIFFY-1263 filed
  #def test_account_admins
  #  admins = @handle.account_admins
  #  assert_equal(1,admins.size)
  #  assert_equal($username,admins[0].username)
  #end

end
