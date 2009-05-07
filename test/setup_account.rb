require 'integration_testbase'
require 'it_cred'
require 'gliffy/handle'

include Gliffy

class SetupAccount < IntegrationTestBase
  def setup
    super
    @handle = Gliffy::Handle.new(@api_root,@cred,HTTPartyAuth.new(@basic_auth))
  end

  def test_do_the_setup
    response = @handle.anything(:create,'accounts.xml',{ :accountName => 'Ruby Client Integration Test Account', :accountType => 'Test' },true)
    File.open('test/functest_cred.rb','w') do |file|
      puts response.account_id
      file.puts "$functest_account_id = #{response.account_id}"
      file.puts "$functest_oauth_consumer_key = '#{response.oauth_consumer_key}'"
      file.puts "$functest_oauth_consumer_secret = '#{response.oauth_consumer_secret}'"
    end
  end
end
