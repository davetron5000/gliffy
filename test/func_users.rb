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

class FUNC_testUserUpdate < FunctionalTestBase
  def setup
    super
    @username = 'user_to_update'
    @handle.user_create(@username)
  end

  def test_update
    email = 'user_to_update@foobar.info'
    @handle.user_update(@username,:email => email)
    user = get_user(@username)
    assert_not_nil user
    assert_equal(email,user.email)
    is_admin = user.is_admin?

    @handle.user_update(@username,:password => 'foobar69')
    # Can't check that it worked; only that if we get here, Gliffy gave us a success message

    new_admin = is_admin ? true : false
    [new_admin,!new_admin].each do |admin_expected|
      @handle.user_update(@username,:admin => admin_expected)
      user = get_user(@username)
      assert_equal(admin_expected,user.is_admin?,user.inspect)

    end
    [new_admin,!new_admin].each do |admin_expected|
      email = admin_expected.to_s + 'user_to_update@foobar.info'
      @handle.user_update(@username,:email => email, :admin => admin_expected)
      user = get_user(@username)
      assert_equal(admin_expected,user.is_admin?,user.inspect)
      assert_equal(email,user.email,user.inspect)
    end

  end

  def teardown
    super
    @handle.user_delete(@username)
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

