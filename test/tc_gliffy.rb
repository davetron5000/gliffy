require 'gliffy/url'
require 'gliffy/response'
require 'gliffy/rest'
require 'gliffy/user'
require 'gliffy/diagram'
require 'gliffy/folder'
require 'gliffy/account'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'webrick'

include Gliffy
include WEBrick

class TC_testGliffy < Test::Unit::TestCase

  class MockRestClient

    def initialize
    end

    def get(url,headers)
      path = url.gsub(/\?.*$/,'')
      File.read("#{path}/index.xml")
    end

    def put(url,headers)
    end

    def post(url,headers)
    end

    def delete(url,headers)
    end
  end

  def setup
    @rest = Rest.new
    @rest.rest_client = MockRestClient.new
    Gliffy::Config.config.account_name='Naildrivin5'
    Gliffy::Config.config.gliffy_root='test/test_doc_root'
  end

  def test_initiate
    user = User.initiate_session('davetron5000',@rest)
    assert(user.success?,user.respond_to?(:message) ? user.message : "Got a #{user.class.to_s} instead of a Gliffy::Response")
    assert_equal('davetron5000',user.username)
  end

  def test_user_folders
    user = User.initiate_session('davetron5000',@rest)
    folders = user.folders
    assert(folders.success?,folders.respond_to?(:message) ? folders.message : "Got a #{folders.class.to_s} instead of a Gliffy::Response")
    assert_equal(1,folders.length)
    assert_equal(2,folders[0].child_folders.length)
  end

end
