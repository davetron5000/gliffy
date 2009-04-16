require 'gliffy/url'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testSigning < Test::Unit::TestCase

  def setup
    @signed_url = SignedURL.new(:consumer_key => 'dpf43f3p2l4k3l03',
                               :consumer_secret => 'kd94hf93k423kf44',
                               :url => 'http://photos.example.net/photos',
                               :access_token => 'nnch734d00sl2jdk',
                               :access_secret => 'pfkkdhi9sl3r4s00',
                               :method => 'GET')
  end

  def test_bad_param_override
    SignedURL::READ_ONLY_PARAMS.keys.each do |param|
      assert_raises(ArgumentError) do 
        @signed_url[param] = 'asdfasdfasdf'
      end
    end
  end

  def test_simple
    @signed_url['file'] = 'vacation.jpg'
    @signed_url['size'] = 'original'

    expected_url = 'http://photos.example.net/photos?file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=kllo9940pd9333jh&oauth_signature=yLAzw2MLOraWc%2B6GbXchR8PzIJI%3D%0A&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk&oauth_version=1.0&size=original'
    assert_equal(expected_url,@signed_url.full_url(1191242096,'kllo9940pd9333jh'))
  end
  def test_simple_bulk_params_set
    params = {
      'file' => 'vacation.jpg',
      'size' => 'original',
    }
    @signed_url.params=params

    expected_url = 'http://photos.example.net/photos?file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=kllo9940pd9333jh&oauth_signature=yLAzw2MLOraWc%2B6GbXchR8PzIJI%3D%0A&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk&oauth_version=1.0&size=original'
    assert_equal(expected_url,@signed_url.full_url(1191242096,'kllo9940pd9333jh'))
  end

=begin
  def test_sign_simple
    url = '/accounts/FooBar/diagrams/45'
    signed_url = SignedURL.new(@api_key,@secret,@root,url)
    assert_equal('http://www.gliffy.com/rest/accounts/FooBar/diagrams/45?apiKey=some_api_key&signature=347cb44d17a026351168e458f3691070',signed_url.full_url)
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
    assert_equal('http://www.gliffy.com/rest/accounts/FooBar/diagrams/45?aaaa=crud&apiKey=some_api_key&blah=foo&signature=c117ddb1476984eb6c72af46b0a7548c&zzzz=booyah+booyah+booyah',signed_url.full_url)
  end
=end
end
