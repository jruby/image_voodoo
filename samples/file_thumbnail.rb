require 'image_science'

# reads in the file specified by ARGV[0], transforms it into a 32-pixel thumbnail,
# and writes it out to the file specified by ARGV[1], using that extension as the
# target format.
ImageScience.with_image(ARGV[0]) do |img|
  img.thumbnail(32) do |img2|
    if ARGV[1]
      img2.save(ARGV[1])
    else
      img2.preview
    end
  end
end
