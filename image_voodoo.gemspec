# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "image_voodoo/version"

Gem::Specification.new do |s|
  s.name        = 'image_voodoo'
  s.version     = ImageVoodoo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Thomas E. Enebo, Charles Nutter, Nick Sieger'
  s.email       = 'tom.enebo@gmail.com'
  s.homepage    = 'http://github.com/jruby/image_voodoo'
  s.summary     = 'Image manipulation in JRuby with ImageScience compatible API'
  s.description = 'Image manipulation in JRuby with ImageScience compatible API'

  s.rubyforge_project = "image_voodoo"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "vendor"]
  s.has_rdoc      = true
end
