require 'gliffy/xml'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testXML < Test::Unit::TestCase

  def test_error
    xml = File.read("test/xml/error.xml")
    response = XML.parse(xml)

    assert_equal(true,response.success)
    assert_equal(404,response.element.http_status)
    assert_equal("That diagram couldn't be found, yo.",response.element.message)
  end

  def test_users
    xml = File.read("test/xml/users.xml");
    response = XML.parse(xml)

    assert_equal(true,response.success)
    users = response.element

    assert_equal(3,users.length)

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
    response = XML.parse(xml)
    assert_equal(true,response.success)

    assert_equal("Some Diagram Name & Stuff",response.element.diagram_name)
    assert_equal("http://www.gliffy.com/rest/diagram_launch.jsp?id=56&foo=bar",response.element.url)

  end

  def test_user_token
    xml = File.read("test/xml/user_token.xml")
    response = XML.parse(xml)

    assert_equal(true,response.success)
    token = response.element

    assert_equal(Time.at(1276432200),token.expiration)
    assert_equal('qwertyuiipasdfghjkl',token.token)
  end
end
