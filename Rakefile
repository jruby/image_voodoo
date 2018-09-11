require 'bundler'
require 'rake/testtask'
Bundler::GemHelper.install_tasks
Bundler.setup

task :default => :test

desc 'Run tests'
task :test do
  Rake::TestTask.new do |t|
    t.libs << 'lib:vendor'
    t.test_files = FileList['test/test*.rb']
  end
end
