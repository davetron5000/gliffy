require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testUser < Test::Unit::TestCase

  def setup
    @user1_id = 666
    @user2_id = @user1_id + 1
    @user1_email = 'dutch@governor.gov'
    @user2_email = 'billy@navajo.gov'
    @user1_username = 'dutch'
    @user2_username = 'billy'
    @user1_admin = true
    @user2_admin = false
    @user1 = { 'id' => @user1_id.to_s,
               'username' => @user1_username,
               'email' => @user1_email,
               'is_admin' => @user1_admin.to_s
    }
    @user2 = { 'id' => @user2_id.to_s,
               'username' => @user2_username,
               'email' => @user2_email,
               'is_admin' => @user2_admin.to_s
    }
  end

  def test_one_user
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'users' => { 
          'user' => @user1
        }
      }
    }))
    assert_user1(response[0])
  end

  def test_two_users
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'users' => { 
          'user' => [ @user1, @user2 ]
        }
      }
    }))
    assert_user1(response[0])
    assert_equal(@user2_id,response[1].user_id)
    assert_equal(@user2_username,response[1].username)
    assert_equal(@user2_email,response[1].email)
    assert_equal(@user2_admin,response[1].is_admin?)
  end

  private

  def assert_user1(user)
    assert_equal(@user1_id,user.user_id)
    assert_equal(@user1_username,user.username)
    assert_equal(@user1_email,user.email)
    assert_equal(@user1_admin,user.is_admin?)
  end
end
