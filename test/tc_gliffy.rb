require 'gliffy/url'
require 'gliffy/response'
require 'gliffy/rest'
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
    Gliffy::Config.config.gliffy_root='test/test_doc_root'
    Gliffy::Response.rest.rest_client=MockRestClient.new
    @account_name = 'Naildrivin5'
  end

  def test_account

    account = Account.find(@account_name)

    assert_not_nil(account)
    if !account.success?
      if account.respond_to? :message
        assert(false,account.message)
      else
        assert(false,"Success FALSE, and returned object was a #{account.class.to_s}, which was not expected")
      end
    end

    assert_equal(@account_name,account.name)
    assert_equal(100,account.max_users)
    assert_equal(:basic,account.type)
    assert_equal(3,account.users.length)
  end

  def test_account_users
    account = Account.find(@account_name)
    assert_equal(3,account.users!.length)
    assert_equal(3,account.users.length)
  end

  def test_account_diagrams
    account = Account.find(@account_name)
    assert_equal(4,account.diagrams!.length)
    assert_equal(4,account.diagrams.length)
  end

  def test_account_diagrams_auto_fetch
    account = Account.find(@account_name)
    assert_equal(4,account.diagrams.length)
  end

  def test_account_folders
    account = Account.find(@account_name)
    folders = account.folders
    assert(1,folders.length)
    assert(1,folders[0].child_folders.length)
    assert(3,folders[0].child_folders[0].child_folders.length)
  end


end
