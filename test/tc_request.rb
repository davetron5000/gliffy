require 'gliffy/request'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'testbase.rb'


include Gliffy


class TC_testRequest < Test::Unit::TestCase
  # Simple Mock of HTTPart that returns the URL that was requested.
  # This allows us to see what URLs were being generated
  class MockHTTParty
    def post(url)
      return url
    end
  end

  def setup
    @account_id = 666
    @username = 'dave'
    @http = MockHTTParty.new
    @cred = Credentials.new('dpf43f3p2l4k3l03',
                            'kd94hf93k423kf44',
                            'Test Cases',
                            @account_id,
                            @username,
                            'nnch734d00sl2jdk',
                            'pfkkdhi9sl3r4s00')
    @api_root = 'http://www.gliffy.com/api/v1.0'
    @request = Request.new(@api_root,@cred)
    @request.http = @http

    # Expose some internals for testing/debug
    class << @request
      attr_reader :api_root
      attr_reader :full_url_no_params
    end
  end

  def test_added_slash
    assert_equal(@api_root + "/",@request.api_root)
  end

  def test_replace_url
    replaced_url = @request.replace_url('/accounts/$account_id/users/$username.xml')
    assert_equal("/accounts/#{@account_id}/users/#{@username}.xml",replaced_url)
  end

  def test_simple_case
    signed_url,nonce,timestamp = get_signed_url_nonce_timestamp("/accounts/#{@account_id}/users/#{@username}.xml")
    signed_url[:action] = 'delete'
    expected_full_url = signed_url.full_url(timestamp,nonce)

    results = @request.delete('accounts/$account_id/users/$username.xml',nil,timestamp,nonce)
    assert_equal(expected_full_url,results)
  end

  def test_more_complex_case
    signed_url,nonce,timestamp = get_signed_url_nonce_timestamp("/accounts/#{@account_id}/users/#{@username}.xml")
    signed_url[:action] = 'update'
    signed_url[:admin] = true
    signed_url[:password] = 'foobar'
    expected_full_url = signed_url.full_url(timestamp,nonce)

    results = @request.update('accounts/$account_id/users/$username.xml',{:admin => true, :password => 'foobar'},timestamp,nonce)
    assert_equal(expected_full_url,results)
  end

  def test_getting_token
    @cred.clear_access_token
    signed_url,nonce,timestamp = get_signed_url_nonce_timestamp("/accounts/#{@account_id}/users/#{@username}/oauth_token.xml")
    description = 'Test Cases'
    signed_url[:description] = description
    signed_url[:action] = 'create'
    expected_full_url = signed_url.full_url(timestamp,nonce)

    results = @request.create('accounts/$account_id/users/$username/oauth_token.xml',{:description => description},timestamp,nonce)
    assert_equal(expected_full_url,results)
  end

  def test_default_method_missing
    assert_raises(NoMethodError) { @request.doit }
  end

  private 
  def get_signed_url_nonce_timestamp(url_part)
    url = @api_root + url_part
    signed_url = SignedURL.new(@cred,url,'POST')
    [signed_url,'321654987','123456789']
  end
end
