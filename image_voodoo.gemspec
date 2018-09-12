# -*- encoding: utf-8 -*-

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'image_voodoo/version'

Gem::Specification.new do |s|
  s.name        = 'image_voodoo'
  s.version     = ImageVoodoo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Thomas E. Enebo, Charles Nutter, Nick Sieger'
  s.email       = 'tom.enebo@gmail.com'
  s.homepage    = 'http://github.com/jruby/image_voodoo'
  s.summary     = 'Image manipulation in JRuby with ImageScience compatible API'
  s.description = 'Image manipulation in JRuby with ImageScience compatible API'

  s.rubyforge_project = 'image_voodoo'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w[lib vendor]
  s.has_rdoc      = true

  s.add_development_dependency 'jar-dependencies'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'ruby-maven'
  s.add_development_dependency 'test-unit'

  s.requirements << 'jar com.drewnoakes, metadata-extractor, 2.11.0'
end
