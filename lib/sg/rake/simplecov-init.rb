require 'simplecov'
SimpleCov.start do
  coverage_dir 'doc/coverage'
  track_files 'lib/**/*.rb'
  track_files 'lib/*/**/*.rb'
  track_files 'bin/*'
  add_filter /([~]|bak)\Z/
  add_group 'Scripts', 'bin'
  add_group 'Libraries', 'lib'
  add_group 'Tests', /(tests|spec)/
end
