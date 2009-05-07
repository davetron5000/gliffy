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

{ :test => { :desc => 'Runs Unit Tests', :prefix => 'tc', :required_file => nil, :coverage => true },
  :inttest => { :desc => 'Runs Integration Tests', :prefix => 'int', :required_file => 'it_cred.rb', :coverage => true },
  :functest => { :desc => 'Runs Functional Tests', :prefix => 'func', :required_file => 'it_cred.rb', :coverage => true },
  :setup_account => { :desc => 'Sets up a Test Account', :prefix => 'setup', :required_file => 'it_cred.rb', :coverage => false },
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
      t.test_files = FileList['test/' + test_info[:prefix] + '_*.rb']
      #t.warning = true
    end
    if test_info[:coverage]
      Rcov::RcovTask.new(('rcov_' + test_name.to_s).to_sym) do |t|
        t.libs << 'lib'
        t.libs << 'test'
        t.libs << 'ext'
        t.test_files = FileList['test/' + test_info[:prefix] + '_*.rb']
      end
    end
  end
end

task :clobber_coverage do
    rm_rf "coverage"
end

task :default => :test

task :publish_rdoc => [:rdoc,:publish]
