Gem::Specification.new do |s|
  s.name        = 'sg'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "Common modules for all SemanticGap projects."
  #s.description = "Much longer explanation of the example!"
  s.authors     = ["Nolan Eakins <sneakin@semanticgap.com>"]
  s.email       = 'support@semanticgap.com'
  s.files       = [ "lib/**/*.rb" ]
  s.homepage    = 'https://oss.semanticgap.com/ruby/sg'
  s.metadata    = {
    "source_code_uri" => "https://github.com/sneakin/sg-gem"
  }
  s.executables = [ 'bin/color.rb' ]
  s.require_paths = [ 'lib' ]
  s.add_runtime_dependency 'rake'
  s.add_dependency 'unicode-display_width'
  s.add_dependency 'unicode-emoji'
end
