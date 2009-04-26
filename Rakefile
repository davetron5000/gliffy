require 'rake/clean'
require 'rake/testtask'
require 'hanna/rdoctask'
require 'rcov/rcovtask'
require 'rubygems'
require 'rake/gempackagetask'
$: << '../grancher/lib'
require 'grancher/task'

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.directory 'html'
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Ruby Client for Gliffy'
end

spec = eval(File.read('gliffy.gemspec'))
 
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

desc 'Runs tests'
Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.libs << 'ext'
  t.test_files = FileList['test/tc_*.rb']
  t.warning = true
end

if File.exists?('test/it_cred.rb')
desc 'Runs integration tests'
Rake::TestTask.new(:inttest) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.libs << 'ext'
  t.test_files = FileList['test/int_*.rb']
  t.warning = true
end
else
  task :inttest do
    $stderr.puts "Integration tests won't run; you need to create test/it_cred.rb"
    $stderr.puts "See the documentation for what this should look like"
  end
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
  t.libs << 'test'
  t.libs << 'ext'
  t.test_files = FileList['test/tc_*.rb']
end

Rcov::RcovTask.new(:rcov_int) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.libs << 'ext'
  t.test_files = FileList['test/int_*.rb']
end

task :default => :test

task :publish_rdoc => [:rdoc,:publish]
