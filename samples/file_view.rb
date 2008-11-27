require 'image_voodoo'

# preview the file specified by ARGV[0] in a swing window
ImageVoodoo.with_image(ARGV[0]) do |img|
  img.preview
end
