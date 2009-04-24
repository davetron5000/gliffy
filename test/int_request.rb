require 'gliffy/credentials'
require 'gliffy/request'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'testbase.rb'
require 'it_cred.rb'

include Gliffy

class HTTPartyAuth
  def initialize(auth)
    @auth = auth
  end

  def post(url)
    HTTParty.post(url,:basic_auth => @auth)
  end
end

class INT_testRequest < Test::Unit::TestCase
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

    @request = Request.new(@api_root,@cred)
    @request.http = HTTPartyAuth.new(@basic_auth)
  end

  def test_get_token
    results = @request.create('accounts/$account_id/users/$username/oauth_token.xml', :description => @cred.description, :protocol_override => :https)
    assert_equal('true',results['response']['success'])
    returned_credentials = results['response']['oauth_token_credentials']
    assert(returned_credentials != nil,results['response'].keys.join(','))
    assert(returned_credentials['oauth_token'] != nil)
    assert(returned_credentials['oauth_token_secret'] != nil)
    [returned_credentials['oauth_token'],returned_credentials['oauth_token_secret']]
  end

  def test_get_account_metadata
    token,secret = test_get_token
    @cred.update_access_token(AccessToken.new(token,secret))
    results = @request.get('accounts/$account_id.xml', :showUsers => true)
    assert(results['response']['success'] == 'true')
    account = results['response']['accounts']['account']
    assert_equal('Premium',account['account_type'])
    assert_equal('TEST',account['name'])
  end
end
