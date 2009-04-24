require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testToken < Test::Unit::TestCase

  def setup
    @token_part = 'foobarbaz'
    @secret_part = 'blahcrudbooyah'
    @create_date = Time.now
    @token = {
        'oauth_token' => @token_part,
        'oauth_token_secret' => @secret_part,
        'create_date' => @create_date.to_i * 1000,
    }
  end

  def test_token
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'oauth_token_credentials' => @token
      }
    }))
    assert_equal(response.class,AccessToken)
    assert_equal(response.token,@token_part)
    assert_equal(response.secret,@secret_part)
  end
end
