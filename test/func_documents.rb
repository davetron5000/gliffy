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
    @users.each { |user| @handle.user_create(user) }
  end

  def teardown
    @created.each { |doc| @handle.document_delete(doc) }
    @folders.each { |folder| @handle.folder_delete(folder) }
    @users.each { |user| @handle.user_delete(user) }
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
