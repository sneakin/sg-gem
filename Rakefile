require 'bundler/setup'
require 'pathname'

NAME = 'sg'
VERSION = '0.0.1'

$ROOT = Pathname.new(__FILE__).dirname

require 'sg/rake/tasks'

namespace :gem do
  file "#{NAME}-#{VERSION}.gem" => 'sg.gemspec' do
    sh("gem build sg.gemspec")
  end
  
  desc "Build the gem."
  task :build => "#{NAME}-#{VERSION}.gem"
end

desc 'Remove any built files.'
task :clean do
  sh("rm -rf #{NAME}*.gem doc/api doc/rdoc doc/yard doc/spec.html")
end
