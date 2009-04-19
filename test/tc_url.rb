require 'gliffy/url'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testURL < Test::Unit::TestCase

  def setup
    @cred = Credentials.new('dpf43f3p2l4k3l03',
                            'kd94hf93k423kf44',
                            'Test Cases',
                            666,
                            'nnch734d00sl2jdk',
                            'pfkkdhi9sl3r4s00')
    @signed_url = SignedURL.new(@cred,
                               'http://photos.example.net/photos',
                               'GET')
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
    signature = 'tR3+Ty81lMeYAr/Fid0kMTYa/WM='
    signature_encoced = 'tR3%2BTy81lMeYAr%2FFid0kMTYa%2FWM%3D'
    expected_url = 'http://photos.example.net/photos?file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=kllo9940pd9333jh&oauth_signature=tR3%2BTy81lMeYAr%2FFid0kMTYa%2FWM%3D&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk&oauth_version=1.0&size=original'
    assert_equal(expected_url,@signed_url.full_url(1191242096,'kllo9940pd9333jh'))
  end

end
