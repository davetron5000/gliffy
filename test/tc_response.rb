require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testResponse < Test::Unit::TestCase

  def test_blank
    response = Response.from_http_response(TC_testResponse::make_response({'response' => {'success' => 'true'}}))
    assert_equal Response,response.class
  end

  def test_method_missing
    r = Response.new({})
    assert_raises(NoMethodError) do
      r.doit(:now,:i_am_here)
    end
  end

  def test_custom_error_callback
    error_message = 'This is a big fat error message'
    message_got = nil
    error_callback = Proc.new { |response,exception| message_got = exception.message }
    Response.from_http_response(TC_testResponse::make_response({ 'response' => { 'error' => error_message, 'success' => 'false'}}),error_callback)
    assert_equal(error_message,message_got)
  end

  def test_default_error_callback
    response = TC_testResponse::make_response(nil)
    assert_raises(NoResponseException) do
      Response.from_http_response(response)
    end

    response = TC_testResponse::make_response({ 'blah' => '' })
    assert_raises(BadResponseException) do
      Response.from_http_response(response)
    end

    response = TC_testResponse::make_response({ 'response' => {} })
    assert_raises(BadResponseException) do
      Response.from_http_response(response)
    end

    response = TC_testResponse::make_response({ 'response' => {'success' => 'false' }})
    assert_raises(RequestFailedException) do
      Response.from_http_response(response)
    end

    response = TC_testResponse::make_response({ 'response' => { 'success' => 'false', 'error' => 'Some Error Message'}})
    assert_raises(RequestFailedException) do
      Response.from_http_response(response)
    end
  end

  def self.make_response(hash)
    class << hash
      def body
        hash.to_s
      end
    end
    hash
  end
end
