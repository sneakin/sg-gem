NAME = 'sg'
VERSION = '0.0.1'

require 'pathname'
require 'rspec/core/rake_task'

rspec_opts = [ ENV['RSPEC_OPTS'] || '' ]

desc 'Run the RSpec test suit'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = rspec_opts.join(' ')
  t.pattern = 'tests/spec/**{,/*/**}/*.spec'
end

namespace :spec do
  desc 'Add options to generate a coverage report.'
  task :coverage do
    rspec_opts << '-Ilib -Itests -rinit'
  end
  
  desc 'Run the RSpec test suit'
  RSpec::Core::RakeTask.new(:fast) do |t|
    t.rspec_opts = [ *rspec_opts, '-t "~slow"' ].join(' ')
    t.pattern = 'tests/spec/**{,/*/**}/*.spec'
  end

  desc 'Run the RSpec test suit with the doc formatter.'
  RSpec::Core::RakeTask.new(:doc) do |t|
    t.rspec_opts = [ *rspec_opts, "-f doc #{rspec_opts}" ].join(' ')
    t.pattern = 'tests/spec/**{,/*/**}/*.spec'
  end

  RSpec::Core::RakeTask.new(:_html) do |t|
    t.rspec_opts = [ *rspec_opts, '-f html -o doc/spec.html' ].join(' ')
    t.pattern = 'tests/spec/**{,/*/**}/*.spec'
  end

  file 'doc/spec.html' => [ 'spec:coverage', 'spec:_html' ]

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

task :doc => [ 'doc:api', 'spec:html' ]

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
