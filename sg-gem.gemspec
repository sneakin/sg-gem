Gem::Specification.new do |s|
  s.name        = 'sg-gem'
  s.version     = '0.3.0'
  s.licenses    = ['MIT']
  s.summary     = "Common modules for all SemanticGap projects."
  #s.description = "Much longer explanation of the example!"
  s.authors     = ["Nolan Eakins <sneakin@semanticgap.com>"]
  s.email       = 'support@semanticgap.com'
  s.files       = [ 'bin/sg-color', 'bin/sg-tabler', 'bin/webrick' ] + Dir.glob("lib/**/*.rb")
  s.homepage    = 'https://oss.semanticgap.com/ruby/sg'
  s.metadata    = {
    "source_code_uri" => "https://github.com/sneakin/sg-gem"
  }
  s.executables = [ 'sg-color', 'sg-tabler' ]
  s.require_paths = [ 'lib' ]
  s.add_dependency 'rake', '~>13.0.0'
  s.add_development_dependency 'bindata'
  s.add_development_dependency 'rdoc', '~>6.5.0'
  s.add_development_dependency 'rspec', '~>3.12.0'
  s.add_development_dependency "simplecov", "~> 0.22.0"
  s.add_development_dependency 'solargraph'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'org-ruby'
  s.add_dependency 'base64'
  s.add_dependency 'ffi'
  s.add_dependency 'matrix'
  s.add_dependency 'ostruct', '0.6.0'
  s.add_dependency 'unicode-display_width', '~>2.5.0'
  s.add_dependency 'unicode-emoji', '~>3.4.0'
  s.add_dependency 'webrick'
end
