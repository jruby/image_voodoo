# frozen_string_literal: true

require 'bundler'
require 'rake/testtask'
require 'jars/installer'
Bundler::GemHelper.install_tasks
Bundler.setup

task :default => %i[vendor_jars test]

desc 'Vendor Jars'
task :vendor_jars do
  test_file = File.expand_path File.join('lib', 'image_voodoo_jars.rb'), __dir__
  Jars::Installer.vendor_jars! unless File.exist? test_file
end

desc 'Run tests'
task :test => :vendor_jars do
  Rake::TestTask.new do |t|
    t.libs << 'lib:vendor'
    t.test_files = FileList['test/test*.rb']
  end
end
