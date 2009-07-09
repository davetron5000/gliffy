require 'rubygems'
require 'rexml/formatters/pretty'
class REXML::Formatters::Pretty
  # fix cockup in RCov
  alias old_wrap wrap
  def wrap(string, width)
    return string;
  end
end
