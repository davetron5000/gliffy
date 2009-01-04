require 'rake/clean'
require 'rake/rdoctask'
require 'rcov/rcovtask'
#require 'rubygems'
#require 'rake/gempackagetask'

Rake::RDocTask.new do |rd|
    rd.main = "README.rdoc"
    rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
end

#spec = eval(File.read('rgliffy.gemspec'))
 
#Rake::GemPackageTask.new(spec) do |pkg|
#    pkg.need_tar = true
#end

desc 'Runs tests'
task :test do |t|
    $: << 'lib'
    $: << 'ext'
    $: << 'test'
    require 'tc_response.rb'
    require 'tc_signing.rb'
    require 'tc_rest.rb'
    require 'gliffy/config'
    class Gliffy::Config
        def self.log_level; Logger::INFO; end
    end
    Test::Unit::UI::Console::TestRunner.run(TC_testRest)
    Test::Unit::UI::Console::TestRunner.run(TC_testResponse)
    Test::Unit::UI::Console::TestRunner.run(TC_testSigning)
end

task :clobber_coverage do
    rm_rf "coverage"
end

desc 'Measures test coverage'
task :coverage => :rcov do
    system("open coverage/index.html") if PLATFORM['darwin']
    rm output_yaml
end

Rcov::RcovTask.new do |t|
  t.libs << 'lib'
  t.libs << 'ext'
  t.test_files = FileList['test/tc_*.rb']
  # t.verbose = true     # uncomment to see the executed command
end


task :default => :test
