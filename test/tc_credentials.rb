require 'gliffy/credentials'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testCredentials < Test::Unit::TestCase
  def test_default_access_token
    cred = Credentials.new('foo','bar','baz',1234,'dave')
    assert_equal(nil,cred.access_token)
    assert(!cred.has_access_token?)
  end

  def test_given_access_token
    cred = Credentials.new('foo','bar','baz',1234,'dave',RequestToken.new('blah','foo'))
    assert_equal('blah',cred.access_token.token)
    assert_equal('foo',cred.access_token.secret)
    assert(cred.has_access_token?)
  end

  def test_bad_args
    assert_raises(ArgumentError) { cred = Credentials.new(nil,nil,nil,nil) }
    assert_raises(ArgumentError) { cred = Credentials.new('foo',nil,nil,nil) }
    assert_raises(ArgumentError) { cred = Credentials.new('foo','bar',nil,nil) }
    assert_raises(ArgumentError) { cred = Credentials.new('foo','bar','',nil) }
    assert_raises(ArgumentError) { cred = Credentials.new('foo','bar','crud',nil) }
  end

  def test_clear_token
    cred = Credentials.new('foo','bar','baz',1234,'dave',RequestToken.new('blah','crud'))
    cred.clear_access_token
    assert_equal(nil,cred.access_token)
  end
  def test_update_token
    cred = Credentials.new('foo','bar','baz',1234,'dave')
    cred.update_access_token(RequestToken.new('blah','crud'))
    assert_equal('blah',cred.access_token.token)
    assert_equal('crud',cred.access_token.secret)
  end

  def test_nonce
    cred = Credentials.new('foo','bar','baz',1234,'dave')
    n1 = cred.nonce
    n2 = cred.nonce
    assert(n1 != n2,"Two nonces shouldn't be the same: #{n1} =? #{n2}")
  end
end
