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

  def test_sign_complex
    url = '/accounts/FooBar/diagrams/45'
    signed_url = SignedURL.new(@api_key,@secret,@root,url)
    signed_url['blah'] = 'foo'
    signed_url['aaaa'] = 'crud'
    signed_url['zzzz'] = 'booyah booyah booyah'
    assert_complex(signed_url)
  end

  def test_sign_complex_2
    url = '/accounts/FooBar/diagrams/45'
    signed_url = SignedURL.new(@api_key,@secret,@root,url)
    params = {
    'blah' => 'foo',
    'aaaa' => 'crud',
    'zzzz' => 'booyah booyah booyah',
    }
    signed_url.params = params
    assert_complex(signed_url)
  end

  private
  def assert_complex(signed_url)
    assert_equal('http://www.gliffy.com/rest/accounts/FooBar/diagrams/45?aaaa=crud&api_key=some_api_key&blah=foo&signature=306ecea0275272976f50882d525cac68&zzzz=booyah+booyah+booyah',signed_url.full_url)
  end
end
