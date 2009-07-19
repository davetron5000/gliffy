spec = Gem::Specification.new do |s| 
  s.name = 'gliffy'
  s.version = '0.9.3'
  s.author = 'David Copeland'
  s.email = 'davidcopeland@naildrivin5.com'
  s.homepage = 'http://davetron5000.github.com/gliffy'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Client to access the Gliffy API'
  s.files = %w(
ext/array_has_response.rb
lib/gliffy/credentials.rb
lib/gliffy/handle.rb
lib/gliffy/request.rb
lib/gliffy/response.rb
lib/gliffy/url.rb
lib/gliffy.rb
bin/gliffy
  )
  s.require_paths << 'ext'
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--title' << 'Gliffy Ruby Client' << '--main' << 'README.rdoc' << '-ri'
  s.add_dependency('httparty', '>= 0.4.2')
  s.add_dependency('ruby-hmac', '>= 0.3.2')
  s.add_dependency('gli', '>= 0.2.1')
  s.bindir = 'bin'
  s.executables << 'gliffy'
end

