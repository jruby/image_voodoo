require 'image_voodoo'

# reads in the file specified by ARGV[0], transforming to greyscale and
# writing to the file specified by ARGV[1]
ImageVoodoo.with_image(ARGV[0]) do |img|
  img.greyscale do |img2|
    if ARGV[1]
      img2.save(ARGV[1])
    else
      img2.preview
    end
  end
end
