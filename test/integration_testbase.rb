require 'test/unit'
require 'test/unit/ui/console/testrunner'

class HTTPartyAuth
  def initialize(auth)
    @auth = auth
  end

  def post(url)
    HTTParty.post(url,:basic_auth => @auth)
  end
end

class IntegrationTestBase < Test::Unit::TestCase
  def test_true
    assert true
  end
end
