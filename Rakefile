NAME = 'sg'
VERSION = '0.0.1'

require 'rspec/core/rake_task'

RSPEC_OPTS = ENV['RSPEC_OPTS'] || ''

desc 'Run the RSpec test suit'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = RSPEC_OPTS
  t.pattern = 'tests/spec/**{,/*/**}/*.spec'
end

namespace :spec do
  desc 'Run the RSpec test suit'
  RSpec::Core::RakeTask.new(:fast) do |t|
    t.rspec_opts = '-t "~slow"'
    t.pattern = 'tests/spec/**{,/*/**}/*.spec'
  end

  desc 'Run the RSpec test suit with the doc formatter.'
  RSpec::Core::RakeTask.new(:doc) do |t|
    t.rspec_opts = "-f doc #{RSPEC_OPTS}"
    t.pattern = 'tests/spec/**{,/*/**}/*.spec'
  end

  RSpec::Core::RakeTask.new(:_html) do |t|
    t.rspec_opts = '-f html -o doc/spec.html'
    t.pattern = 'tests/spec/**{,/*/**}/*.spec'
  end

  file 'doc/spec.html' => 'spec:_html'

  desc 'Run the RSpec test suit with HTML output to doc/spec.html'
  task :html => 'doc/spec.html'
end

namespace :doc do
  desc 'Generate the API documentation as HTML.'
  task :api do
    require 'rdoc/rdoc'
    rdoc = RDoc::RDoc.new
    rdoc.document %w{-o doc/api lib}
  end
end

namespace :gem do
  file "#{NAME}-#{VERSION}.gem" => 'sg.gemspec' do
    sh("gem build sg.gemspec")
  end
  
  desc "Build the gem."
  task :build => "#{NAME}-#{VERSION}.gem"
end

desc 'Remove any built files.'
task :clean do
  sh("rm -rf #{NAME}*.gem doc/api doc/spec.html")
end
