spec = Gem::Specification.new do |s| 
  s.name = 'gliffy'
  s.version = '0.1.6'
  s.author = 'David66666land'
  s.email = 'davidcopeland@naildrivin5.com'
  s.homepage = 'http://davetron5000.github.com/gliffy'
  s.platform = Gem::Platform::RUBY
  s.summary = 'client to access the Gliffy API'
  s.files = %w(
ext/array_has_response.rb
bin/gliffy
lib/gliffy/account.rb
lib/gliffy/cli.rb
lib/gliffy/commands/delete.rb
lib/gliffy/commands/edit.rb
lib/gliffy/commands/get.rb
lib/gliffy/commands/list.rb
lib/gliffy/commands/new.rb
lib/gliffy/commands/url.rb
lib/gliffy/commands.rb
lib/gliffy/config.rb
lib/gliffy/diagram.rb
lib/gliffy/folder.rb
lib/gliffy/handle.rb
lib/gliffy/response.rb
lib/gliffy/rest.rb
lib/gliffy/url.rb
lib/gliffy/user.rb
lib/gliffy.rb
  )
  s.require_paths << 'ext'
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--title' << 'Gliffy Ruby Client' << '--main' << 'README.rdoc' << '-ri'
  s.add_dependency('davetron5000-rest-client', '>= 0.5.3')
  s.add_dependency('davetron5000-gli', '>= 0.1.4')
  s.bindir = 'bin'
  s.executables << 'gliffy'
end

