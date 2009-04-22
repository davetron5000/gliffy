require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testResponse < Test::Unit::TestCase

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
  end


  def test_blank
    response = Response.from_http_response(make_response({'response' => {}}))
    assert_equal Response,response.class
  end

  def test_accounts
    response = Response.from_http_response(make_response({
      'response' => { 
        'success' => 'true',
        'accounts' => { 
          'account' => @one_account_hash
        }
      }
    }))
    assert_equal(Response,response.class)
    assert_equal(@name,response.name)
    assert_equal(@account_id,response.account_id)
    assert_equal(@account_type,response.account_type)
    assert_equal(@max_users,response.max_users)
    assert_equal(@expiration_date.to_s,response.expiration_date.to_s)
  end

  def test_many_accounts
    response = Response.from_http_response(make_response({
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

  def test_method_missing
    r = Response.new({})
    assert_raises(NoMethodError) do
      r.doit(:now,:i_am_here)
    end
  end

  private

  def make_response(hash)
    class << hash
      def body
        hash.to_s
      end
    end
    hash
  end
end
