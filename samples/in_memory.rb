require 'image_voodoo'

# reads in the image at ARGV[0], transforms it into a 32-pixel thumbnail in-memory,
# and writes it back out as a png to the file specified by ARGV[1]
ImageVoodoo.with_bytes(File.read(ARGV[0])) do |img|
  img.thumbnail(32) do |img2|
    File.open(ARGV[1], 'w') do |file|
      file.write(img2.bytes('png'))
    end
  end
end
