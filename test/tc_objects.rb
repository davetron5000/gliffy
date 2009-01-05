require 'gliffy/user'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy
class TC_testObjects < Test::Unit::TestCase
  def test_token_expired
    token = UserToken.new(Time.now,'asdfasdfasdfasdf')
    assert(token.expired?)
  end

  def test_error_to_s
    assert_equal("404: blah",Error.new("blah",404).to_s)
  end

  def test_encode_folder_path
    path = 'this/is/a/simple/path'
    assert_equal(path,Folder.encode_path_elements(path))
    path = '/this/is/a/simple/path'
    assert_equal(path,Folder.encode_path_elements(path))
    path = 'this/is/a/more complex/path'
    assert_equal(path.gsub(/ /,'+'),Folder.encode_path_elements(path))
  end

end
