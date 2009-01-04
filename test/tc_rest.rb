require 'gliffy/rest'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class MockRestClient

  XML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><response xmlns="http://www.gliffy.com" success="true" />'

  def method_missing(symbol,*args)
    @method = symbol
    @url = args[0]
    @headers = args[1]
    return XML
  end

  def method_requested; @method; end
  def url_requested; @url; end
  def headers_sent; @headers; end

end

class TC_testRest < Test::Unit::TestCase

  def setup
    Gliffy::Config.config.api_key = 'abcdefghijklmnop'
    Gliffy::Config.config.secret_key = 'qwertyuiop'
    Gliffy::Config.config.gliffy_root = 'http://www.google.com'

    @api_key = Gliffy::Config.config.api_key
    @secret = Gliffy::Config.config.secret_key
    @rest = Rest.new
    @rest.rest_client = MockRestClient.new
    @root = Gliffy::Config.config.gliffy_root
    @simple_url = "/accounts/Naildrivin5"
    @params = {
      'foo' => 'bar',
      'blah' => 'crud crud',
      'baz' => 'QUUX',
    }
    @headers = {
      'Accept' => 'image/jpeg',
      'If-None-Match' => 'asdfasdfasdfasdf',
    }
    @rest.logger.level = Logger::WARN
  end

  def test_get_simple; test(:get); end
  def test_put_simple; test(:put); end
  def test_post_simple; test(:post); end
  def test_delete_simple; test(:delete); end

  def test_get_with_headers; test(:get,nil,@headers); end
  def test_put_with_headers; test(:put,nil,@headers); end
  def test_post_with_headers; test(:post,nil,@headers); end
  def test_delete_with_headers; test(:delete,nil,@headers); end

  def test_get_with_params; test(:get,@params); end
  def test_put_with_params; test(:put,@params); end
  def test_post_with_params; test(:post,@params); end
  def test_delete_with_params; test(:delete,@params); end

  def test_get_with_params_and_headers; test(:get,@params,@headers); end
  def test_put_with_params_and_headers; test(:put,@params,@headers); end
  def test_post_with_params_and_headers; test(:post,@params,@headers); end
  def test_delete_with_params_and_headers; test(:delete,@params,@headers); end

  def test_bad_method_call
    assert_raises(NoMethodError) do
      @rest.head(@simple_url)
    end
    assert_raises(ArgumentError) do
      @rest.get
    end
  end

  private

  def test(symbol,params=nil,headers={})
    @rest.send(symbol,@simple_url,params,headers)
    if params
      signature = 'ac5327ce462ff01f4a4da1b8957d1d2a'
    else
      signature = 'a86e9c6736963496210883d0413bc971'
    end
    param_string = '&'
    if (params)
      params.keys.sort.each() do |param|
        param_string += param
        param_string += '='
        param_string += CGI::escape(params[param])
        param_string += '&'
      end
    end
    param_string.gsub!(/\&$/,'')
    expected_url = "#{@root}#{@simple_url}?apiKey=#{@api_key}#{param_string}&signature=#{signature}"
    assert_equal(expected_url,@rest.get_url(@simple_url,params))
    do_asserts(symbol,headers,expected_url)
  end

  def do_asserts(method,headers,expected_url)

    assert_equal(method,@rest.rest_client.method_requested)
    assert_equal(expected_url,@rest.rest_client.url_requested)
    assert_equal(headers.length,@rest.rest_client.headers_sent.length)
    headers.each_pair do |key,value|
      assert_equal(value,@rest.rest_client.headers_sent[key])
    end
    @rest.rest_client.headers_sent.each_pair do |key,value|
      assert_equal(value,headers[key])
    end
  end
end
