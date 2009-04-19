require 'rubygems'
require 'rexml/formatters/pretty'

=begin for JUnit later
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
    @tests_run.each_key do |key|
      puts "RAN RAN RAN #{key}" if !@tests_failed[key]
    end
    @tests_failed.each_key do |key|
      puts "FAIL FAIL FAIL '#{key}'"
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
=end
class REXML::Formatters::Pretty
  # fix cockup in RCov
  def wrap(string, width)
    return string;
    # Recursivly wrap string at width.
    return string if string.length <= width
    place = string.rindex(' ', width) # Position in string with last ' ' before cutoff
    return string if place.nil?
    return string[0,place] + "\n" + wrap(string[place+1..-1], width)
  end
end
