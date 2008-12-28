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
  end

  def test_get_simple
    @rest.get(@simple_url)
    do_asserts(:get)
  end

  def test_put_simple
    @rest.put(@simple_url)
    do_asserts(:put)
  end

  def test_post_simple
    @rest.post(@simple_url)
    do_asserts(:post)
  end

  def test_delete_simple
    @rest.post(@simple_url)
    do_asserts(:post)
  end

  private

  def do_asserts(method)

    assert_equal(method,@mock_rest_client.method_requested)
    signature = 'a86e9c6736963496210883d0413bc971'
    assert_equal("#{@root}#{@simple_url}?apiKey=#{@api_key}&signature=#{signature}",@mock_rest_client.url_requested)
    assert_equal(0,@mock_rest_client.headers_sent.length)
  end
end
