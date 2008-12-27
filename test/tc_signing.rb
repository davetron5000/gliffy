require 'gliffy/rest'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testSigning < Test::Unit::TestCase

  def setup
    @root = 'http://www.gliffy.com/rest'
    @api_key = 'some_api_key'
    @secret = 'some_big_secret'
  end

  def test_sign_simple

    url = '/accounts/FooBar/diagrams/45'

    signed_url = SignedURL.new(@api_key,@secret,@root,url)

    assert_equal('http://www.gliffy.com/rest/accounts/FooBar/diagrams/45?api_key=some_api_key&signature=4efd52954a65a736526def9cd1b7fe96',signed_url.full_url)
  end
end
