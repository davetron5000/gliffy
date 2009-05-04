require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testFolder < Test::Unit::TestCase

  def setup
    @f1_id = 45
    @f1_name ="foo"
    @f1_path = "ROOT/foo"

    @f2_id = 46
    @f2_name ="ROOT"
    @f2_path = "ROOT"
    @f2_default = true

    @f3_id = 47
    @f3_name ="bar"
    @f3_path = "ROOT/foo/bar"

    @f4_id = 48
    @f4_name ="baz"
    @f4_path = "ROOT/foo/baz"
  end

  def test_two_folders
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'folders' => { 
          'folder' => [
            {
              'id' => @f3_id.to_s,
              'name' => @f3_name,
              'path' => @f3_path,
            },
            {
              'id' => @f4_id.to_s,
              'name' => @f4_name,
              'path' => @f4_path,
            }
          ]
        }
      }
    }))
    assert_equal(2,response.size)
    assert_equal(@f3_id,response[0].folder_id)
    assert_equal(@f3_name,response[0].name)
    assert_equal(@f3_path,response[0].path)
    assert_equal(@f4_id,response[1].folder_id)
    assert_equal(@f4_name,response[1].name)
    assert_equal(@f4_path,response[1].path)
  end

  def test_root_folder
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'folders' => { 
          'folder' => {
            'id' => @f2_id.to_s,
            'name' => @f2_name,
            'path' => @f2_path,
            'folder' => {
              'id' => @f1_id.to_s,
              'name' => @f1_name,
              'path' => @f1_path,
              'folder' => [
                {
                  'id' => @f3_id.to_s,
                  'name' => @f3_name,
                  'path' => @f3_path,
                },
                {
                  'id' => @f4_id.to_s,
                  'name' => @f4_name,
                  'path' => @f4_path,
                }
              ]
            }
          }
        }
      }
    }))
    response = response[0]
    assert_equal(@f2_id,response.folder_id)
    assert_equal(@f2_name,response.name)
    assert_equal(@f2_path,response.path)
    assert_equal(1,response.child_folders.size)
    assert_equal(@f1_id,response.child_folders[0].folder_id)
    assert_equal(@f1_name,response.child_folders[0].name)
    assert_equal(@f1_path,response.child_folders[0].path)
    assert_equal(2,response.child_folders[0].child_folders.size)
    assert_equal(@f3_id,response.child_folders[0].child_folders[0].folder_id)
    assert_equal(@f3_name,response.child_folders[0].child_folders[0].name)
    assert_equal(@f3_path,response.child_folders[0].child_folders[0].path)
    assert_equal(@f4_id,response.child_folders[0].child_folders[1].folder_id)
    assert_equal(@f4_name,response.child_folders[0].child_folders[1].name)
    assert_equal(@f4_path,response.child_folders[0].child_folders[1].path)
  end
end
