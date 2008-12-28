require 'rake/clean'
require 'rake/rdoctask'
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
    $: << 'test'
    require 'tc_response.rb'
    require 'tc_signing.rb'
    require 'tc_rest.rb'
    Test::Unit::UI::Console::TestRunner.run(TC_testResponse)
    Test::Unit::UI::Console::TestRunner.run(TC_testSigning)
    Test::Unit::UI::Console::TestRunner.run(TC_testRest)
end

task :default => :test
