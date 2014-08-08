require 'image_voodoo'

ImageVoodoo.with_image(ARGV[0]) do |img|
  10.times do |i|
    quality = i / 10.0
    img.quality(quality) do |qimg|
      qimg.save "#{ARGV[0]}_#{quality}.jpg"
    end
  end
end
