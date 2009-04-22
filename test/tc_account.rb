require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testAccount < Test::Unit::TestCase

  def setup
    @name = 'Skynet'
    @account_id = 101
    @account_type = 'Premium'
    @max_users = 100
    @expiration_date = Time.now
    @one_account_hash = {
            'account_type' => @account_type,
            'id' => @account_id.to_s,
            'max_users' => @max_users.to_s,
            'terms' => 'true',
            'name' => @name,
            'expiration_date' => (@expiration_date.to_i * 1000).to_s
    }
    @two_account_hash = {
            'account_type' => @account_type,
            'id' => (@account_id + 1).to_s,
            'max_users' => @max_users.to_s,
            'terms' => 'true',
            'name' => @name + "2",
            'expiration_date' => (@expiration_date.to_i * 1000).to_s
    }
    @user1_id = 666
    @user2_id = @user1_id + 1
    @user1_email = 'dutch@governor.gov'
    @user2_email = 'billy@navajo.gov'
    @user1_username = 'dutch'
    @user2_username = 'billy'
    @user1_admin = true
    @user2_admin = false
    @one_account_hash_with_users = {
            'account_type' => @account_type,
            'id' => @account_id.to_s,
            'max_users' => @max_users.to_s,
            'terms' => 'true',
            'name' => @name,
            'expiration_date' => (@expiration_date.to_i * 1000).to_s,
            'users' => { 'user' => [
              { 'id' => @user1_id.to_s,
                'username' => @user1_username,
                'email' => @user1_email,
                'is_admin' => @user1_admin.to_s
              },
              { 'id' => @user2_id.to_s,
                'username' => @user2_username,
                'email' => @user2_email,
                'is_admin' => @user2_admin.to_s
              }
            ]},
    }
  end

  def test_accounts_with_users
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'accounts' => { 
          'account' => @one_account_hash_with_users
        }
      }
    }))
    assert_one_account(response)
    assert_equal(2,response.users.size)
    assert_equal(@user1_id,response.users[0].user_id)
    assert_equal(@user2_id,response.users[1].user_id)
    assert_equal(@user1_username,response.users[0].username)
    assert_equal(@user2_username,response.users[1].username)
    assert_equal(@user1_email,response.users[0].email)
    assert_equal(@user2_email,response.users[1].email)
    assert_equal(@user1_admin,response.users[0].is_admin?)
    assert_equal(@user2_admin,response.users[1].is_admin?)
  end

  def assert_one_account(response)
    assert_equal(Response,response.class)
    assert_equal(@name,response.name)
    assert_equal(@account_id,response.account_id)
    assert_equal(@account_type,response.account_type)
    assert_equal(@max_users,response.max_users)
    assert_equal(@expiration_date.to_s,response.expiration_date.to_s)
  end

  def test_accounts
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'accounts' => { 
          'account' => @one_account_hash
        }
      }
    }))
    assert_one_account(response)
  end

  def test_many_accounts
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'accounts' => { 
          'account' => [ @one_account_hash, @two_account_hash ]
        }
      }
    }))
    assert_equal(Array,response.class)
    assert_equal(2,response.size)
    i = 0
    acct = response[0]
    assert_equal(@name,acct.name)
    assert_equal(@account_id,acct.account_id)
    assert_equal(@account_type,acct.account_type)
    assert_equal(@max_users,acct.max_users)
    assert_equal(@expiration_date.to_s,acct.expiration_date.to_s)

    acct = response[1]
    assert_equal(@name + "2",acct.name)
    assert_equal(@account_id + 1,acct.account_id)
    assert_equal(@account_type,acct.account_type)
    assert_equal(@max_users,acct.max_users)
    assert_equal(@expiration_date.to_s,acct.expiration_date.to_s)
  end
end
