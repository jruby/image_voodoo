require 'java'

# Hide in ImageVoodoo so awt.rb can see this and we will not polute global
class ImageVoodoo
  java_import java.awt.Graphics2D

  # Re-open to add convenience methods.
  class Graphics2D
    def draw_this_image(image)
      draw_image image, 0, 0, nil
    end
  end
end
