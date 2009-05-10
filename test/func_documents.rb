require 'gliffy/credentials'
require 'gliffy/handle'
require 'functional_testbase.rb'

include Gliffy

class FUNC_testFolderCreateDelete < FunctionalTestBase
  def setup
    setup_handle
    @created = Array.new
    @folders = %w(doc_foo doc_bar doc_baz)
    @users = %w(docuser_foo docuser_bar)

    @folders.each { |folder| @handle.folder_create(folder) }
    @users.each do |user| 
      begin
      @handle.user_create(user) 
      rescue Exception => e
        puts "Exception when creating #{user}"
        puts e.message
      end
    end
  end

  def teardown
    @created.each { |doc| @handle.document_delete(doc) }
    @folders.each { |folder| @handle.folder_delete(folder) }
    @users.each do |user| 
      begin
        @handle.user_delete(user) 
      rescue Exception => e
        puts e.message
      end
    end
  end

  def test_create_delete
    assert_not_nil @created
    assert_not_nil @folders
    assert_not_nil @users
    [
      {:name => 'My New Document ' + Time.now.to_f.to_s,:folder => nil},
      {:name => 'My Other New Document ' + Time.now.to_f.to_s,:folder => @folders[0]},
      {:name => 'My Other Other New Document ' + Time.now.to_f.to_s,:folder => @folders[1]},
    ].each do |test_case|
      name = test_case[:name]
      folder = test_case[:folder]
      created_document = @handle.document_create(name,folder)
      @created << created_document.document_id
      assert_equal(name,created_document.name,test_case.inspect)
      documents = @handle.account_documents
      assert_document_in_list(name,documents,test_case)
      if !folder.nil?
        documents = @handle.folder_documents(folder)
        assert_document_in_list(name,documents,test_case)
      end
      meta_data = @handle.document_get_metadata(created_document.document_id)
      assert_equal(name,meta_data.name)
      assert_equal(1,meta_data.num_versions)
    end
  end
  private

  def assert_document_in_list(name,documents,test_case)
    found = false
    documents.each do |document|
      found = document.name == name
    end
    assert(found,"Didn't find #{name}, but found " + documents.map { |d| d.name }.join(',') + test_case.inspect)
  end
end

class FUNC_testFolderGet < FunctionalTestBase
  BLANK_XML ='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><stage keygen_seq="1"><pageObj drawingHeight="200" drawingWidth="200" istt="false" stg="0" pb="0" gr="0" fill="16777215" height="5000" width="5000"><objects/></pageObj></stage>'
  BLANK_SVG = '<svg xmlns:x="http://ns.adobe.com/Extensibility/1.0/" xmlns:i="http://ns.adobe.com/AdobeIllustrator/10.0/" xmlns:graph="http://ns.adobe.com/Graphs/1.0/" xmlns:a="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"  xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="201" height="201"><defs></defs><rect stroke="#000000" stroke-width="1" fill="#ffffff" x="0" y="0" width="200" height="200"/></svg>'
  
  def setup
    setup_handle
    @created = Array.new
    @folders = %w(doc2_foo doc2_bar doc2_baz)
    @users = %w(docuser2_foo docuser2_bar)

    @folders.each { |folder| @handle.folder_create(folder) }
    @users.each { |user| @handle.user_create(user) }
  end

  def teardown
    @created.each { |doc| @handle.document_delete(doc) }
    @folders.each { |folder| @handle.folder_delete(folder) }
    @users.each { |user| @handle.user_delete(user) }
  end

  PNG_BYTES = ['89', '50', '4e', '47', 'd', 'a', '1a', 'a' ]
  JPEG_BYTES = [ 'ff', 'd8', 'ff', 'e0' ]

  def test_get_document
    name = 'My Document Imana Get ' + Time.now.to_f.to_s[0..49]
    created_document = @handle.document_create(name)
    @created << created_document.document_id
    meta_data = @handle.document_get_metadata(created_document.document_id)
    assert_equal(name,meta_data.name)
    xml = @handle.document_get(created_document.document_id,:xml)
    assert_equal(BLANK_XML,xml)
    svg = @handle.document_get(created_document.document_id,:svg)
    assert_equal(BLANK_SVG,svg)
    jpg = @handle.document_get(created_document.document_id,:jpg)
    JPEG_BYTES.each_index do |i|
      assert_equal(JPEG_BYTES[i],jpg[i].to_s(16),"Doesn't appear to be a valid JPEG at byte #{i}")
    end
    png = @handle.document_get(created_document.document_id,:png)
    PNG_BYTES.each_index do |i|
      assert_equal(PNG_BYTES[i],png[i].to_s(16),"Doesn't appear to be a valid PNG at byte #{i}")
    end
  end
end
