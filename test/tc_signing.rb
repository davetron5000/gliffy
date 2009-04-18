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
    do_simple_assert
  end

  def test_simple_bulk_params_set
    params = {
      'file' => 'vacation.jpg',
      'size' => 'original',
    }
    @signed_url.params=params
    do_simple_assert
  end

  private
  def do_simple_assert
    expected_url = 'http://photos.example.net/photos?file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=kllo9940pd9333jh&oauth_signature=yLAzw2MLOraWc%2B6GbXchR8PzIJI%3D%0A&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk&oauth_version=1.0&size=original'
    assert_equal(expected_url,@signed_url.full_url(1191242096,'kllo9940pd9333jh'))
  end

end
