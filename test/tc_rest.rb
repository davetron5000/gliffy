require 'gliffy/rest'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class MockRestClient

  def method_missing(symbol,*args)
    @method = symbol
    @url = args[0]
    @headers = args[1]
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><response xmlns="http://www.gliffy.com" success="true" />'
  end

  def method_requested; @method; end
  def url_requested; @url; end
  def headers_sent; @headers; end

end

class TC_testRest < Test::Unit::TestCase

  def setup
    @api_key = 'abcdefghijklmnop'
    @secret = 'qwertyuiop'
    @root = 'http://www.google.com'
    @rest = Rest.new(@api_key,@secret,@root)
    @mock_rest_client = MockRestClient.new
    @rest.rest_client = @mock_rest_client
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
    do_asserts(symbol,signature,param_string,headers)
  end

  def do_asserts(method,signature,param_string,headers)

    assert_equal(method,@mock_rest_client.method_requested)
    assert_equal("#{@root}#{@simple_url}?apiKey=#{@api_key}#{param_string}&signature=#{signature}",@mock_rest_client.url_requested)
    assert_equal(headers.length,@mock_rest_client.headers_sent.length)
    headers.each_pair do |key,value|
      assert_equal(value,@mock_rest_client.headers_sent[key])
    end
    @mock_rest_client.headers_sent.each_pair do |key,value|
      assert_equal(value,headers[key])
    end
  end
end
