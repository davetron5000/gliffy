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

  def test_delete_token
    account = @handle.account_get
    assert_equal(101,account.account_id)
    token = @cred.access_token.token
    @handle.delete_token
    account = @handle.account_get
    assert_equal(101,account.account_id)
    # Not testing for diff token, since this test is all static
  end

  def test_account_get
    account = @handle.account_get
    assert_equal(101,account.account_id)
    assert_equal('Naildrivin5',account.name)
    assert_equal('Basic',account.account_type)
    assert_equal(100,account.max_users)
    assert_users(account.users)
  end

  def test_account_admins
    admins = @handle.account_admins
    assert_equal(2,admins.size)

    assert_equal(45,admins[0].user_id)
    assert_equal('davetron5000',admins[0].username)
    assert(admins[0].is_admin?)

    assert_equal(447,admins[1].user_id)
    assert_equal('testuser@gliffy.com',admins[1].username)
    assert(admins[1].is_admin?)
  end

  def test_account_folders
    root_folder = @handle.account_folders
    assert_equal('ROOT',root_folder.name)
    assert_equal(true,root_folder.is_default?)
    assert_equal(2,root_folder.child_folders.size)
    assert_equal(0,root_folder.child_folders[0].child_folders.size)
    assert_equal('tmp',root_folder.child_folders[0].name)
    assert_equal(3,root_folder.child_folders[1].child_folders.size)
    assert_equal('gliffy',root_folder.child_folders[1].child_folders[0].name)
    assert_equal('vimdoclet',root_folder.child_folders[1].child_folders[1].name)
    assert_equal('fauxml',root_folder.child_folders[1].child_folders[2].name)
  end

  def test_account_documents
    documents = @handle.account_documents
    assert_equal(2,documents.size)
    assert_equal('Booze DB',documents[0].name)
    assert_equal(208,documents[0].owner.user_id)
    assert_equal('Hounds Room',documents[1].name)
    assert_equal(202,documents[1].owner.user_id)
  end

  def test_account_users
    users = @handle.account_users
    assert_users(users)
  end

  def test_document_meta_data
    document = @handle.document_get_metadata(1000003)
    assert_equal(1000003,document.document_id)
    assert_equal('Booze DB',document.name)
    assert_equal('moe',document.owner.username)
    assert_equal(2,document.versions.size)
  end

  def teardown
    @s.shutdown
  end

  private 

  def assert_users(users)
    assert_equal(4,users.size)
    assert_equal(45,users[0].user_id)
    assert(users[0].is_admin?)
    assert_equal(446,users[1].user_id)
    assert(!users[1].is_admin?)
    assert_equal(447,users[2].user_id)
    assert(users[2].is_admin?)
    assert_equal(333,users[3].user_id)
    assert(!users[3].is_admin?)
  end

end
