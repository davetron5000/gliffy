require 'gliffy/credentials'
require 'gliffy/handle'
require 'functional_testbase.rb'

include Gliffy


class FUNC_testFolderCreateDelete < FunctionalTestBase
  def setup
    setup_handle
    @folders = %w(foo bar baz)
    @folders.each { |folder| @handle.folder_create(folder) }
  end

  def teardown
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

class FUNC_testFolderGrantRevoke < FunctionalTestBase
  def setup
    setup_handle
    @folders = %w(gr_foo gr_bar)
    @folders.each { |folder| @handle.folder_create(folder) }
    @users = %w(user_foo user_bar user_baz)
    @users.each { |user| @handle.user_create(user) }
  end

  def teardown
    @folders.each { |folder| @handle.folder_delete(folder) }
    @users.each { |user| @handle.user_delete(user) }
  end

  def test_grant_revoke
    @handle.folder_add_user(@folders[0],@users[0])
    @handle.folder_add_user(@folders[1],@users[1])

    assert_user_in_folder(@users[0],@folders[0])
    assert_user_not_in_folder(@users[1],@folders[0])

    assert_user_in_folder(@users[1],@folders[1])
    assert_user_not_in_folder(@users[0],@folders[1])

    @handle.folder_remove_user(@folders[0],@users[0])
    assert_user_not_in_folder(@users[0],@folders[0])
  end

  private

  def assert_user_not_in_folder(username,foldername)
    users = @handle.folder_users(foldername)
    users.each do |user|
      assert(user.username != username,"Found #{username} where I wasn't expecting (in folder #{foldername})") 
    end
  end

  def assert_user_in_folder(username,foldername)
    users = @handle.folder_users(foldername)
    found = false
    all_users = []
    users.each do |user|
      found = user.username == username
      all_users << user.username
    end
    assert(found,"Found only #{all_users.join(',')}, but not #{username}")
  end
end

