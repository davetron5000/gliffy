require 'gliffy/credentials'
require 'gliffy/handle'
require 'functional_testbase.rb'

include Gliffy


class FUNC_testUserCreateDelete < FunctionalTestBase
  def setup
    super
    @users = %w(user_foo user_bar user_baz)
    @users.each { |user| @handle.user_create(user) }
  end

  def teardown
    super
    @users.each { |user| @handle.user_delete(user) }
  end

  def test_create_delete
    account_users = @handle.account_users
    found = {}
    account_users.each do |account_user|
      found[account_user.username] = true if @users.include? account_user.username
    end
    assert_equal(@users.size,found.keys.size,found.inspect)
  end
end

