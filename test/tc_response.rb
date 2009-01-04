require 'gliffy/config'
require 'gliffy/response'
require 'gliffy/user'
require 'gliffy/diagram'
require 'gliffy/folder'
require 'gliffy/account'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testResponse < Test::Unit::TestCase

  def test_empty
    xml = File.read("test/xml/empty.xml")
    response = Response.from_xml(xml)

    assert_equal(true,response.success?)

  end

  def test_error
    xml = File.read("test/xml/error.xml")
    error = Response.from_xml(xml)

    assert_equal(false,error.success?)
    assert_equal(404,error.http_status)
    assert_equal("That diagram couldn't be found, yo.",error.message)
  end

  def test_users
    xml = File.read("test/xml/users.xml");
    users = Response.from_xml(xml)

    assert_equal(true,users.success?)

    assert_users(users)
  end

  def test_bad_account
    xml = File.read("test/xml/accounts_bad.xml")
    assert_raises(RuntimeError) do
      response = Response.from_xml(xml)
    end
  end

  def assert_users(users)

    assert_equal(3,users.length)

    users.each do |user|
      assert_equal(false,user.id.nil?)
    end

    assert_equal(45,users[0].id)
    assert_equal(true,users[0].is_admin?)
    assert_equal('davetron5000',users[0].username)
    assert_equal('davetron5000@blah.com',users[0].email)

    assert_equal(446,users[1].id)
    assert_equal(false,users[1].is_admin?)
    assert_equal('foobar',users[1].username)
    assert_equal(nil,users[1].email)

    assert_equal(333,users[2].id)
    assert_equal(false,users[2].is_admin?)
    assert_equal(nil,users[2].username)
    assert_equal('blah.crud@something.info',users[2].email)

  end

  def test_launch_link
    xml = File.read("test/xml/launch_link.xml")
    link = Response.from_xml(xml)
    assert_equal(true,link.success?)

    assert_equal("Some Diagram Name & Stuff",link.diagram_name)
    assert_equal("http://www.gliffy.com/rest/diagram_launch.jsp?id=56&foo=bar",link.url)

  end

  def test_diagrams

    xml = File.read("test/xml/diagrams.xml")
    diagrams = Response.from_xml(xml)
    assert_equal(true,diagrams.success?)

    assert_equal(3,diagrams.length)

    diagram = diagrams[0]
    assert_equal(45,diagram.id)
    assert_equal(4,diagram.num_versions)
    assert_equal(true,diagram.is_public?)
    assert_equal(false,diagram.is_private?)
    assert_equal(Time.at(1191846600),diagram.create_date)
    assert_equal(Time.at(1192192200),diagram.mod_date)
    assert_equal('Some Diagram',diagram.name)
    assert_equal('davec',diagram.owner_username)
    assert_equal(Time.at(1192192200),diagram.published_date)

    diagram = diagrams[1]
    assert_equal(46,diagram.id)
    assert_equal(5,diagram.num_versions)
    assert_equal(false,diagram.is_public?)
    assert_equal(true,diagram.is_private?)
    assert_equal(Time.at(1181846600),diagram.create_date)
    assert_equal(Time.at(1182192200),diagram.mod_date)
    assert_equal('Some Other Diagram',diagram.name)
    assert_equal('rudy',diagram.owner_username)
    assert_equal(nil,diagram.published_date)

    diagram = diagrams[2]
    assert_equal(47,diagram.id)
    assert_equal(6,diagram.num_versions)
    assert_equal(false,diagram.is_public?)
    assert_equal(false,diagram.is_private?)
    assert_equal(Time.at(1181886600),diagram.create_date)
    assert_equal(Time.at(1182892200),diagram.mod_date)
    assert_equal('Yet Another Diagram',diagram.name)
    assert_equal('amy',diagram.owner_username)
    assert_equal(nil,diagram.published_date)

  end

  def test_user_token
    xml = File.read("test/xml/user_token.xml")
    user_token = Response.from_xml(xml)

    assert_equal(true,user_token.success?)

    assert_equal(Time.at(1276432200),user_token.expiration)
    assert_equal('qwertyuiipasdfghjkl',user_token.token)
  end

  def test_folders

    xml = File.read("test/xml/folders.xml")
    folders = Response.from_xml(xml)
    assert_equal(true,folders.success?)

    assert_equal(1,folders.length)

    folder = folders[0]
    assert_equal(45,folder.id)
    assert_equal(true,folder.default?)
    assert_equal('ROOT',folder.name)
    assert_equal('ROOT',folder.path)
    assert_equal(2,folder.child_folders.length)

    tmp = folder.child_folders[0]
    projects = folder.child_folders[1]

    assert_equal(46,tmp.id)
    assert_equal(false,tmp.default?)
    assert_equal('tmp',tmp.name)
    assert_equal('ROOT/tmp',tmp.path)
    assert_equal(0,tmp.child_folders.length)

    assert_equal(47,projects.id)
    assert_equal(false,projects.default?)
    assert_equal('projects',projects.name)
    assert_equal('ROOT/projects',projects.path)
    assert_equal(3,projects.child_folders.length)

    gliffy = projects.child_folders[0]
    vimdoclet = projects.child_folders[1]
    fauxml = projects.child_folders[2]

    assert_equal(48,gliffy.id)
    assert_equal(false,gliffy.default?)
    assert_equal('gliffy',gliffy.name)
    assert_equal('ROOT/projects/gliffy',gliffy.path)
    assert_equal(0,gliffy.child_folders.length)

    assert_equal(49,vimdoclet.id)
    assert_equal(false,vimdoclet.default?)
    assert_equal('vimdoclet',vimdoclet.name)
    assert_equal('ROOT/projects/vimdoclet',vimdoclet.path)
    assert_equal(0,vimdoclet.child_folders.length)

    assert_equal(50,fauxml.id)
    assert_equal(false,fauxml.default?)
    assert_equal('fauxml',fauxml.name)
    assert_equal('ROOT/projects/fauxml',fauxml.path)
    assert_equal(0,fauxml.child_folders.length)
  end

  def test_accounts
    xml = File.read("test/xml/accounts.xml")
    accounts = Response.from_xml(xml)
    assert_equal(true,accounts.success?)

    assert_equal(2,accounts.length)

    account = accounts[0]

    assert_equal(45,account.id)
    assert_equal(100,account.max_users)
    assert_equal(:basic,account.type)
    assert_equal('Some Test Account',account.name)
    assert_equal(Time.at(1276432200),account.expiration_date)
    assert_equal(0,account.users.length)

    account = accounts[1]
    assert_equal(48,account.id)
    assert_equal(5,account.max_users)
    assert_equal(:premium,account.type)
    assert_equal('Some Other Test Account',account.name)
    assert_equal(Time.at(1276432200),account.expiration_date)
    assert_equal(3,account.users.length)

    assert_users(account.users)
  end
end
