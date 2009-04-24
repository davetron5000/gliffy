require 'gliffy/request'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'testbase.rb'


include Gliffy


class TC_testRequest < Test::Unit::TestCase
  @@xml_crud = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
  # Simple Mock of HTTPart that returns the URL that was requested.
  # This allows us to see what URLs were being generated
  class MockHTTParty
    def initialize(response=nil,nil_means_nil=false)
      @response = response
      @nil_means_nil = nil_means_nil
    end
    def post(url)
      return nil if @nil_means_nil && @response.nil?
      return @response.nil? ? url : @response
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
                            :http,
                            RequestToken.new('nnch734d00sl2jdk','pfkkdhi9sl3r4s00'))
    @api_root = 'www.gliffy.com/api/1.0'
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

  def test_custom_error_callback
    error_message = 'This is a big fat error message'
    @request.http = MockHTTParty.new({ 'response' => { 'error' => error_message, 'success' => 'false'}})
    message_got = nil
    @request.error_callback = Proc.new { |response,exception| message_got = exception.message }
    @request.create('/accounts/$account_id/users/$username/oauth_token.xml')
    assert_equal(error_message,message_got)
  end

  def test_default_error_callback
    @request.http = MockHTTParty.new(nil,true)
    assert_raises(NoResponseException) do
      @request.create('/accounts/$account_id/users/$username/oauth_token.xml')
    end

    @request.http = MockHTTParty.new({ 'blah' => '' })
    assert_raises(BadResponseException) do
      @request.create('/accounts/$account_id/users/$username/oauth_token.xml')
    end

    @request.http = MockHTTParty.new({ 'response' => {} })
    assert_raises(BadResponseException) do
      @request.create('/accounts/$account_id/users/$username/oauth_token.xml')
    end

    @request.http = MockHTTParty.new({ 'response' => {'success' => 'false' }})
    assert_raises(RequestFailedException) do
      @request.create('/accounts/$account_id/users/$username/oauth_token.xml')
    end

    @request.http = MockHTTParty.new({ 'response' => { 'success' => 'false', 'error' => 'Some Error Message'}})
    assert_raises(RequestFailedException) do
      @request.create('/accounts/$account_id/users/$username/oauth_token.xml')
    end
  end

  def test_simple_case
    @request.error_callback = Proc.new {|response,message|}
    signed_url,nonce,timestamp = get_signed_url_nonce_timestamp("/accounts/#{@account_id}/users/#{@username}.xml")
    signed_url[:action] = 'delete'
    expected_full_url = signed_url.full_url(timestamp,nonce)

    results = @request.delete('accounts/$account_id/users/$username.xml',nil,timestamp,nonce)
    assert_equal(expected_full_url,results)
  end

  def test_more_complex_case
    @request.error_callback = Proc.new {|response,message|}
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
    @request.error_callback = Proc.new {|response,message|}
    signed_url,nonce,timestamp = get_signed_url_nonce_timestamp("/accounts/#{@account_id}/users/#{@username}/oauth_token.xml","https")
    description = 'Test Cases'
    signed_url[:description] = description
    signed_url[:action] = 'create'
    expected_full_url = signed_url.full_url(timestamp,nonce)

    results = @request.create('accounts/$account_id/users/$username/oauth_token.xml',{:description => description,:protocol_override => :https},timestamp,nonce)
    assert_equal(expected_full_url,results)
  end

  def test_default_method_missing
    assert_raises(NoMethodError) { @request.doit }
  end

  private 
  def get_signed_url_nonce_timestamp(url_part,protocol=nil)
    protocol = @cred.default_protocol.to_s if protocol.nil?
    url = protocol + "://" + @api_root + url_part
    signed_url = SignedURL.new(@cred,url,'POST')
    [signed_url,'321654987','123456789']
  end
end
