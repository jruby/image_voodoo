require 'java'

# Hide in ImageVoodoo so awt.rb can see this and we will not polute global
class ImageVoodoo
  java_import java.awt.image.BufferedImage

  # Re-open to add convenience methods.
  class BufferedImage
    def each
      height.times { |j| width.times { |i| yield i, j } }
    end
  end
end
