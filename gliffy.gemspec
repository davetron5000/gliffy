spec = Gem::Specification.new do |s| 
  s.name = 'gliffy'
  s.version = '0.1.1'
  s.author = 'David Copeland'
  s.email = 'davidcopeland@naildrivin5.com'
  s.homepage = 'http://davetron5000.github.com/gliffy'
  s.platform = Gem::Platform::RUBY
  s.summary = 'client to access the Gliffy API'
  s.files = %w(
ext/array_has_response.rb
lib/gliffy/account.rb
lib/gliffy/cli.rb
lib/gliffy/commands/commands.rb
lib/gliffy/config.rb
lib/gliffy/diagram.rb
lib/gliffy/folder.rb
lib/gliffy/gliffy.rb
lib/gliffy/response.rb
lib/gliffy/rest.rb
lib/gliffy/url.rb
lib/gliffy/user.rb
lib/gliffy.rb
bin/gliffy
  )
  s.require_paths << 'ext'
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--title' << 'Gliffy Ruby Client' << '--main' << 'README.rdoc' << '-ri'
  s.add_dependency('technoweenie-rest-client', '>= 0.5.1')
  s.bindir = 'bin'
  s.executables << 'gliffy'
end

