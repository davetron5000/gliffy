
require 'gliffy/response'
require 'testbase.rb'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

include Gliffy

class TC_testDocument < Test::Unit::TestCase

  def setup
    @d1_id = 666
    @d1_private = true
    @d1_public = nil
    @d1_num_versions = 10
    @d1_create_date = Time.at(Time.now.to_i - 1000)
    @d1_mod_date = Time.now
    @d1_name = 'Kindergarten Seating Chart'
    @d1_published_date = Time.now
    
    @d1_u_id = 45
    @d1_u_email = 'notatumah@cops.gov'
    @d1_u_name = 'notatumah'
    @d1_u_admin = false
    
    @d1 = {
      'id' => @d1_id.to_s,
      'is_private' => @d1_private.to_s,
      'is_public' => @d1_public.to_s,
      'num_versions' => @d1_num_versions.to_s,
      'create_date' => ms_to_time(@d1_create_date),
      'mod_date' => ms_to_time(@d1_mod_date),
      'name' => @d1_name.to_s,
      'published_date' => ms_to_time(@d1_published_date),
      'owner' => {
        'id' => @d1_u_id,
        'email' => @d1_u_email,
        'username' => @d1_u_name,
        'is_admin' => @d1_u_admin.to_s,
      }
    }

    @d2_id = 667
    @d2_private = nil
    @d2_public = true
    @d2_num_versions = 3
    @d2_create_date = Time.at(Time.now.to_i - 1000)
    @d2_mod_date = Time.now
    @d2_name = 'Escape Plan'
    @d2_published_date = Time.now

    @d2_u_id = 45
    @d2_u_email = 'notatumah@cops.gov'
    @d2_u_name = 'notatumah'
    @d2_u_admin = false

    @d2 = {
    'id' => @d2_id.to_s,
    'is_private' => @d2_private.to_s,
    'is_public' => @d2_public.to_s,
    'num_versions' => @d2_num_versions.to_s,
    'create_date' => ms_to_time(@d2_create_date),
    'mod_date' => ms_to_time(@d2_mod_date),
    'name' => @d2_name.to_s,
    'published_date' => ms_to_time(@d2_published_date),
      'owner' => {
        'id' => @d2_u_id,
        'email' => @d2_u_email,
        'username' => @d2_u_name,
        'is_admin' => @d2_u_admin.to_s,
      }
    }

    @d3_id = 668
    @d3_private = nil
    @d3_public = nil
    @d3_num_versions = 3
    @d3_create_date = Time.at(Time.now.to_i - 1000)
    @d3_mod_date = Time.now
    @d3_name = 'Fire Drill Workflow'
    @d3_published_date = Time.now
    
    @d3_u_id = 46
    @d3_u_email = 'kimable@cops.gov'
    @d3_u_name = 'kimable'
    @d3_u_admin = true

    @d3_v1_create_date = Time.now
    @d3_v1_num = 1
    @d3_v1_id = 1

    @d3_v2_create_date = Time.now
    @d3_v2_num = 2
    @d3_v2_id = 2

    @d3_v3_create_date = Time.now
    @d3_v3_num = 3
    @d3_v3_id = 3
    @owner = {
      'id' => @d3_u_id,
      'email' => @d3_u_email,
      'username' => @d3_u_name,
      'is_admin' => @d3_u_admin.to_s,
    }

    @d3 = {
      'id' => @d3_id.to_s,
      'is_private' => @d3_private.to_s,
      'is_public' => @d3_public.to_s,
      'num_versions' => @d3_num_versions.to_s,
      'create_date' => ms_to_time(@d3_create_date),
      'mod_date' => ms_to_time(@d3_mod_date),
      'name' => @d3_name.to_s,
      'published_date' => ms_to_time(@d3_published_date),
      'owner' => @owner,
      'versions' => {
        'version' => [
          {
            'create_date' => ms_to_time(@d3_v1_create_date),
            'num' => @d3_v1_num.to_s,
            'id' => @d3_v1_id.to_s,
            'owner' => @owner,
          },
          {
            'create_date' => ms_to_time(@d3_v2_create_date),
            'num' => @d3_v2_num.to_s,
            'id' => @d3_v2_id.to_s,
            'owner' => @owner,
          },
          {
            'create_date' => ms_to_time(@d3_v3_create_date),
            'num' => @d3_v3_num.to_s,
            'id' => @d3_v3_id.to_s,
            'owner' => @owner,
          }
        ]
      }
    }
  end

  def test_single_diagram
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'documents' => { 
          'document' => @d1
        }
      }
    }))
    response = response[0]
    assert_document1(response)
  end

  def test_single_diagram_with_versions
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'documents' => { 
          'document' => @d3
        }
      }
    }))
    response = response[0]
    assert_document3(response)
  end

  def test_multiple_diagrams
    response = Response.from_http_response(TC_testResponse::make_response({
      'response' => { 
        'success' => 'true',
        'documents' => { 
          'document' => [@d1,@d2,@d3]
        }
      }
    }))
    assert_document1(response[0])
    assert_document2(response[1])
    assert_document3(response[2])
  end

  private

  def assert_document1(doc)
      assert_equal( @d1_id, doc.document_id)
      assert_equal( @d1_private == true, doc.is_private?)
      assert_equal( @d1_public == true, doc.is_public?)
      assert_equal( @d1_num_versions, doc.num_versions)
      assert_equal( @d1_create_date.to_s, doc.create_date.to_s)
      assert_equal( @d1_mod_date.to_s, doc.mod_date.to_s)
      assert_equal( @d1_name, doc.name)
      assert_equal( @d1_published_date.to_s, doc.published_date.to_s)
      owner = doc.owner
      assert_equal(@d1_u_id,owner.user_id)
      assert_equal(@d1_u_email,owner.email)
      assert_equal(@d1_u_name,owner.username)
      assert_equal(@d1_u_admin,owner.is_admin?)
      assert_equal(nil,doc.versions)
  end
  def assert_document2(doc)
      assert_equal( @d2_id, doc.document_id)
      assert_equal( @d2_private == true, doc.is_private?)
      assert_equal( @d2_public == true, doc.is_public?)
      assert_equal( @d2_num_versions, doc.num_versions)
      assert_equal( @d2_create_date.to_s, doc.create_date.to_s)
      assert_equal( @d2_mod_date.to_s, doc.mod_date.to_s)
      assert_equal( @d2_name, doc.name)
      assert_equal( @d2_published_date.to_s, doc.published_date.to_s)
      owner = doc.owner
      assert_equal(@d2_u_id,owner.user_id)
      assert_equal(@d2_u_email,owner.email)
      assert_equal(@d2_u_name,owner.username)
      assert_equal(@d2_u_admin,owner.is_admin?)
      assert_equal(nil,doc.versions)
  end
  def assert_document3(doc)
      assert_equal( @d3_id, doc.document_id)
      assert_equal( @d3_private == true, doc.is_private?)
      assert_equal( @d3_public == true, doc.is_public?)
      assert_equal( @d3_num_versions, doc.num_versions)
      assert_equal( @d3_create_date.to_s, doc.create_date.to_s)
      assert_equal( @d3_mod_date.to_s, doc.mod_date.to_s)
      assert_equal( @d3_name, doc.name)
      assert_equal( @d3_published_date.to_s, doc.published_date.to_s)
      owner = doc.owner
      assert_equal(@d3_u_id,owner.user_id)
      assert_equal(@d3_u_email,owner.email)
      assert_equal(@d3_u_name,owner.username)
      assert_equal(@d3_u_admin,owner.is_admin?)
      assert_equal(3,doc.versions.size)

      assert_equal(@d3_v1_create_date.to_s,doc.versions[0].create_date.to_s)
      assert_equal(@d3_v1_num,doc.versions[0].num)
      assert_equal(@d3_v1_id,doc.versions[0].version_id)

      owner = doc.versions[0].owner
      assert_equal(@d3_u_id,owner.user_id)
      assert_equal(@d3_u_email,owner.email)
      assert_equal(@d3_u_name,owner.username)
      assert_equal(@d3_u_admin,owner.is_admin?)

      assert_equal(@d3_v2_create_date.to_s,doc.versions[1].create_date.to_s)
      assert_equal(@d3_v2_num,doc.versions[1].num)
      assert_equal(@d3_v2_id,doc.versions[1].version_id)

      owner = doc.versions[1].owner
      assert_equal(@d3_u_id,owner.user_id)
      assert_equal(@d3_u_email,owner.email)
      assert_equal(@d3_u_name,owner.username)
      assert_equal(@d3_u_admin,owner.is_admin?)

      assert_equal(@d3_v3_create_date.to_s,doc.versions[2].create_date.to_s)
      assert_equal(@d3_v3_num,doc.versions[2].num)
      assert_equal(@d3_v3_id,doc.versions[2].version_id)

      owner = doc.versions[2].owner
      assert_equal(@d3_u_id,owner.user_id)
      assert_equal(@d3_u_email,owner.email)
      assert_equal(@d3_u_name,owner.username)
      assert_equal(@d3_u_admin,owner.is_admin?)


  end

  def ms_to_time(ms)
    (ms.to_i * 1000).to_s
  end
end
