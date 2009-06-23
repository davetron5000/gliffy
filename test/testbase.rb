require 'rubygems'
require 'rexml/formatters/pretty'

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

class REXML::Formatters::Pretty
  # fix cockup in RCov
  alias old_wrap wrap
  def wrap(string, width)
    return string;
  end
end
