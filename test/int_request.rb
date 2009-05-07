require 'gliffy/credentials'
require 'gliffy/request'
require 'integration_testbase.rb'
require 'it_cred.rb'

include Gliffy

class INT_testRequest < IntegrationTestBase
  def setup
    super
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
    assert_equal(@account_type,account['account_type'])
    assert_equal(@account_name,account['name'])
  end
end
