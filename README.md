# ImageVoodoo

## DESCRIPTION:

ImageVoodoo is an Image manipulation library with a ImageScience-compatible API
for JRuby.

http://github.com/jruby/image_voodoo

## FEATURES/PROBLEMS:

* Uses java.awt and javax.image APIs native to Java to perform image manipulation; no other dependencies needed.
* Includes image_voodoo command-line utility for quick resizing of images, "image_voodoo --help" for usage.
* Due to lack of TIFF support in ImageIO it is also not supported yet by image_voodoo. If you need it, create an issue in GitHub.
* **JPEG CMYK support** is thanks to work of Werner Randelshofer and [Monte Media Library](http://www.randelshofer.ch/monte/). Monte Media Library is provided under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/) license.
* Now supports reading a variety of EXIF data.  This also supports new function --orient based on how phones typically save photo data.

## SYNOPSIS:

```ruby
  ImageVoodoo.with_image(ARGV[0]) do |img|
    img.cropped_thumbnail(100) { |img2| img2.save "CTH.jpg" }
    img.with_crop(100, 200, 400, 600) { |img2| img2.save "CR.jpg" }
    img.thumbnail(50) { |img2| img2.save "TH.jpg" }
    img.resize(100, 150) do |img2|
      img2.save "HEH.jpg"
      img2.save "HEH.png"
    end
    img.quality(0.75).save("reduced.jpg")
  end
```

image_voodoo can also be run from the commandline:

```text
% image_voodoo -p a.gif --thumbnail 50 -p --save a_thumb.gif
```

In this command-line you will preview a.gif which will pop up a rendered a.gif on your screen;  Then you will scale your image to a thumb to a 50 pixel size; then preview the new thumbnail image; then save it to a_thumb.gif.  The CLI tool uses the same names as the API and can be a very handly command-line tool.

## REQUIREMENTS:

* JRuby

## INSTALL:

* jruby -S gem install image_voodoo
