require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testResponse < Test::Unit::TestCase

  def test_blank
    response = Response.from_http_response(TC_testResponse::make_response({'response' => {}}))
    assert_equal Response,response.class
  end

  def test_method_missing
    r = Response.new({})
    assert_raises(NoMethodError) do
      r.doit(:now,:i_am_here)
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
