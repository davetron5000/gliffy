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

  def test_noop
  end
end
