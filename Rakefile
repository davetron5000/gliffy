require 'rake/clean'
require 'rake/testtask'
require 'hanna/rdoctask'
require 'rcov/rcovtask'
require 'rubygems'
require 'rake/gempackagetask'

begin
  $: << '../grancher/lib'
  require 'grancher/task'

  Grancher::Task.new do |g|
    g.branch = 'gh-pages'
    g.push_to = 'origin'
    g.directory 'html'
  end
rescue
  puts "cd ../ ; git clone git://github.com/judofyr/grancher.git"
  puts "if you want to manage the GitHub Pages page"
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Ruby Client for Gliffy'
end

spec = eval(File.read('gliffy.gemspec'))
 
Rake::GemPackageTask.new(spec) do |pkg|
end

{ :test => { :desc => 'Runs Unit Tests', :prefix => 'tc_', :required_file => nil, :coverage => true },
  :inttest => { :desc => 'Runs Integration Tests', :prefix => 'int_', :required_file => 'it_cred.rb', :coverage => true },
  :functest => { :desc => 'Runs Functional Tests', :prefix => 'func_', :required_file => 'functest_cred.rb', :coverage => true },
  :alltest => { :desc => 'Runs All Tests at Once', :prefix => '', :required_file => 'functest_cred.rb', :coverage => true },
  :setup_account => { :desc => 'Sets up a Test Account', :prefix => 'setup_', :required_file => 'it_cred.rb', :coverage => false },
}.each do |test_name,test_info|
  if test_info[:required_file] && !File.exists?('test/' + test_info[:required_file])
    task test_name do
      $stderr.puts "you need to create test/#{test_info[:required_file]} to run these tests"
      $stderr.puts "See the documentation for what this should look like"
    end
  else
    desc test_info[:desc]
    Rake::TestTask.new(test_name) do |t|
      t.libs << 'lib'
      t.libs << 'test'
      t.libs << 'ext'
      t.test_files = FileList['test/' + test_info[:prefix] + '*.rb']
    end
    if test_info[:coverage]
      Rcov::RcovTask.new(('rcov_' + test_name.to_s).to_sym) do |t|
        t.libs << 'lib'
        t.libs << 'test'
        t.libs << 'ext'
        t.test_files = FileList['test/' + test_info[:prefix] + '*.rb']
      end
    end
  end
end

task :clobber_coverage do
    rm_rf "coverage"
end

task :default => :test

task :publish_rdoc => [:rdoc,:publish]

require 'test/unit/ui/console/testrunner'

class Test::Unit::UI::Console::TestRunner

  alias :old_setup_mediator :setup_mediator 
  def setup_mediator
    @tests_run = Hash.new
    @tests_failed = Hash.new
    old_setup_mediator
    @mediator.add_listener(Test::Unit::TestCase::STARTED,&method(:test_was_started))
    @mediator.add_listener(Test::Unit::TestResult::FAULT,&method(:test_has_failed))
  end

  alias :old_start :start
  def start
    retval = old_start
    File.open("junit_output.xml","w") do |file|
      file.puts "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
      file.puts "<testsuite errors=\"0\" skipped=\"0\" tests=\"#{@tests_run.size}\" time=\"#{Time.now.to_i}\""
      file.puts "failures=\"#{@tests_failed.size}\" name=\"com.gliffy.ruby.unitTests\">"
      @tests_run.each_key do |key|
        file.puts "<testcase time=\"0\" name=\"#{key}\" />" if !@tests_failed[key]
      end
      @tests_failed.each_key do |test|
        file.puts "<testcase time=\"0\" name=\"#{test.test_name}\">"
        file.puts "<failure type=\"com.gliffy.ruby.unitTestFailure\" message=\"#{test.message.gsub(/\n/,' ')} failed\" />"
        file.puts "</testcase>"
      end
      file.puts "</testsuite>"
    end
    return retval
  end

  def test_was_started(name)
    @tests_run[name] = true
  end

  def test_has_failed(name)
    @tests_failed[name] = true
  end
end

