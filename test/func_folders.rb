require 'gliffy/credentials'
require 'gliffy/handle'
require 'functional_testbase.rb'

include Gliffy


class FUNC_testFolderCreateDelete < FunctionalTestBase
  def setup
    super
    @folders = %w(foo bar baz)
    @folders.each { |folder| @handle.folder_create(folder) }
  end

  def teardown
    super
    @folders.each { |folder| @handle.folder_delete(folder) }
  end

  def test_create_delete
    account_folders = @handle.account_folders
    found = {}
    account_folders.each do |account_folder|
      if account_folder.name == 'ROOT'
        account_folder.child_folders.each do |child|
          found[child.name] = true if @folders.include? child.name
        end
      end
    end
    assert_equal(@folders.size,found.keys.size,found.inspect)
  end
end

