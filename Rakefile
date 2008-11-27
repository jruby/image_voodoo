MANIFEST = FileList["bin/*", "Manifest.txt", "Rakefile", "README.txt", "LICENSE.txt", "lib/**/*", "samples/*","test/**/*"]

file "Manifest.txt" => :manifest
task :manifest do
  File.open("Manifest.txt", "w") {|f| MANIFEST.each {|n| f << "#{n}\n"} }
end
Rake::Task['manifest'].invoke # Always regen manifest, so Hoe has up-to-date list of files

$LOAD_PATH << 'lib'
require 'image_voodoo/version'
begin
  require 'hoe'
  Hoe.new("image_voodoo", ImageVoodoo::VERSION) do |p|
    p.rubyforge_name = "jruby-extras"
    p.url = "http://jruby-extras.rubyforge.org/image_voodoo"
    p.author = "Thomas Enebo, Charles Nutter and JRuby contributors"
    p.email = "enebo@acm.org, headius@headius.com"
    p.summary = "Image manipulation in JRuby with ImageScience compatible API"
    p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
    p.description = "Install this gem and require 'image_voodoo' to load the library."
  end.spec.dependencies.delete_if { |dep| dep.name == "hoe" }
rescue LoadError
  puts "You need Hoe installed to be able to package this gem"
rescue => e
  p e.backtrace
  puts "ignoring error while loading hoe: #{e.to_s}"
end
