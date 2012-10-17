require 'image_voodoo'

ImageVoodoo.with_image(ARGV[0]) { |img| img.preview }
