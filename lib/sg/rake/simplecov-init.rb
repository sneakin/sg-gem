require 'simplecov'
SimpleCov.start do
  command_name File.basename($0)
  enable_for_subprocesses true
  enable_coverage :branch
  enable_coverage_for_eval
  coverage_dir 'doc/coverage'
  track_files 'lib/**/*.rb'
  track_files 'bin/*'
  track_files '*/bin/*'
  add_filter /([~]|bak)\Z/
  add_group 'Scripts', 'bin'
  add_group 'Libraries', 'lib'
  add_group 'Tests', /(tests|spec)/
  use_merging = true

  if cid=ENV['COV_CHILD']
    command_name "#{File.basename($0)} #{cid || 0}"
    print_error_status = false
    formatter SimpleCov::Formatter::SimpleFormatter
  end
  
  at_fork do |pid|
    SimpleCov.start do
      cid = ENV['COV_CHILD'] = (1 + ENV.fetch('COV_CHILD', 0).to_i).to_s
      command_name "#{command_name} #{cid}"
      print_error_status = false
      formatter SimpleCov::Formatter::SimpleFormatter
    end
  end
end

ENV['COVERAGE']='1'
