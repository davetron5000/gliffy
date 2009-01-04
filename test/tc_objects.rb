require 'gliffy/user'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy
class TC_testObjects < Test::Unit::TestCase
  def test_token_expired
    token = UserToken.new(Time.now,'asdfasdfasdfasdf')
    assert(token.expired?)
  end

  def test_error_to_s
    assert_equal("404: blah",Error.new("blah",404).to_s)
  end

end
