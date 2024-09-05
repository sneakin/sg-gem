NAME = 'sg'
VERSION = '0.0.1'

require 'pathname'
require 'rspec/core/rake_task'

ROOT = Pathname.new(__FILE__).dirname

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

use_rdoc = !!(ENV.fetch('USE_RDOC', '0') =~ /(y|1)/i)
use_yard = !!(ENV.fetch('USE_YARD', '1') =~ /(y|1)/i)
failed_yard = true
  
namespace :doc do
  if use_yard
    begin
      require 'yard'

      desc 'Generate the API documentation as HTML.'
      YARD::Rake::YardocTask.new(:yard) do |t|
        t.files   = [ 'Rakefile', 'lib/sg.rb', 'bin/*[^~]', '{bin,lib,tests}/**/*.{rb,spec}', '-', 'README.md', 'COPYING' ]
        t.options = ['--title', NAME, '-o', ROOT.join('doc', 'yard').to_s, '-m', 'markdown', '-e', 'lib/sg/yard/refine.rb', '-e', 'lib/sg/yard/refine.rb', '-p', ROOT.join('templates').to_s]
      end
      
      failed_yard = false

      desc 'Generate the API docs.'
      task :api => [ 'doc:yard' ]
      
      file 'doc/api' do
        FileUtils.ln_sf('yard', 'doc/api')
      end
    rescue LoadError
    end
  end
  
  if use_rdoc || failed_yard
    require 'rdoc/task'

    RDoc::Task.new(:rdoc) do |t|
      t.main = "README.md"
      t.rdoc_dir = 'doc/rdoc'
      t.options += %w{--all --markup markdown}
      t.rdoc_files.include('README.md', 'COPYING', 'Rakefile', 'bin/*[^~]', '{bin,lib,tests}/**/*.{rb,spec}')
    end
    
    desc 'Generate the API docs.'
    task :api => [ 'doc:rdoc' ]

    if failed_yard
      file 'doc/api' do
        FileUtils.ln_sf('rdoc', 'doc/api')
      end
    end
  end
end

desc 'Generate the API docs and spec doc.'
task :doc => [ 'doc:api', 'doc/api', 'spec:html' ]

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
