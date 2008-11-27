= ImageVoodoo

== DESCRIPTION:

ImageVoodoo is an Image manipulation library with a ImageScience-compatible API
for JRuby.

http://jruby-extras.rubyforge.org/image_voodoo/

== FEATURES/PROBLEMS:

* Uses java.awt and javax.image APIs native to Java to perform image manipulation; no other dependencies needed.
* Includes image_voodoo command-line utility for quick resizing of images, "image_voodoo --help" for usage.

== SYNOPSIS:

  ImageVoodoo.with_image(ARGV[0]) do |img|
    img.cropped_thumbnail(100) { |img2| img2.save "CTH.jpg" }
    img.with_crop(100, 200, 400, 600) { |img2| img2.save "CR.jpg" }
    img.thumbnail(50) { |img2| img2.save "TH.jpg" }
    img.resize(100, 150) do |img2|
      img2.save "HEH.jpg"
      img2.save "HEH.png"
    end
  end


== REQUIREMENTS:

* JRuby

== INSTALL:

* jruby -S gem install image_voodoo
