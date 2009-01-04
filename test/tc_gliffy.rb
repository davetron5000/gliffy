require 'gliffy/url'
require 'gliffy/response'
require 'gliffy/rest'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testGliffy < Test::Unit::TestCase

  def setup
  end

  def test_noop
  end

  def not_ready_test_init

    account_name = 'Naildrivin5'
    account = Account.find(account_name)

    assert_not_nil(account)
    assert(account.success?,account.message)

    assert_equal(account_name,account.name)
    assert_equal(100,account.max_users)
    assert_equal(:basic,account.type)
    assert_equal(5,account.users.size)
  end

end
