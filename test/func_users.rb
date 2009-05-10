require 'gliffy/credentials'
require 'gliffy/handle'
require 'functional_testbase.rb'

include Gliffy


class FUNC_testUserCreateDelete < FunctionalTestBase
  def setup
    setup_handle
    @users = %w(user_foo user_bar user_baz)
    @users.each { |user| @handle.user_create(user) }
  end

  def teardown
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

class FUNC_testUserUpdate < FunctionalTestBase
  def setup
    setup_handle
    @username_to_update = 'user_to_update'
    @handle.user_create(@username_to_update)
  end

  def test_update
    email = 'user_to_update@foobar.info'
    @handle.user_update(@username_to_update,:email => email)
    user = get_user(@username_to_update)
    assert_not_nil user
    assert_equal(email,user.email)

    @handle.user_update(@username_to_update,:password => 'foobar69')
    # Can't check that it worked; only that if we get here, Gliffy gave us a success message

    [true, false].each do |admin_expected|
      @handle.user_update(@username_to_update,:admin => admin_expected)
      user = get_user(@username_to_update)
      assert_equal(admin_expected,user.is_admin?,user.inspect)
    end

    [true, false].each do |admin_expected|
      email = admin_expected.to_s + 'user_to_update@foobar.info'
      @handle.user_update(@username_to_update,:email => email, :admin => admin_expected)
      user = get_user(@username_to_update)
      assert_equal(admin_expected,user.is_admin?,user.inspect)
      assert_equal(email,user.email,user.inspect)
    end

    admins = @handle.account_admins
    assert_equal(1,admins.size)
    assert_equal(@username,admins[0].username)
  end

  def teardown
    @handle.user_delete(@username_to_update)
  end

  private

  def get_user(username)
    users = @handle.account_users
    users.each do |user|
      return user if user.username == username
    end
    nil
  end
end

