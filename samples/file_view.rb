class ImageVoodoo; NEEDS_HEAD = true; end

require 'image_voodoo'

ImageVoodoo.with_image(ARGV[0], &:preview)
