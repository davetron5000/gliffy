require 'gliffy/request'
require 'gliffy/handle'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'testbase.rb'
require 'webrick'

include WEBrick
include Gliffy

class AllGetHTTP
  def post(url)
    if url =~ /^https:/
      url.gsub!(/^https/,'http')
    end
    HTTParty.get(url)
  end
end

class TC_testHandle < Test::Unit::TestCase
  def setup
    @s = HTTPServer.new(:Port => 2000,
                        :DocumentRoot => 'test/test_doc_root')
    ['INT', 'TERM'].each {|signal| 
      trap(signal) {@s.shutdown}
    }

    Thread.new do
      @s.start
    end
    @cred = Credentials.new('what',
                            'ever',
                            'Ruby Client - Integration Tests',
                            101,
                            'testuser@gliffy.com')
    @api_root = 'localhost:2000'
    @handle = Gliffy::Handle.new(@api_root,@cred,AllGetHTTP.new)
  end

  def test_webrick
    account = @handle.account_get
    assert_equal(101,account.account_id)
    assert_equal('Naildrivin5',account.name)
  end

  def teardown
    @s.shutdown
  end
end
