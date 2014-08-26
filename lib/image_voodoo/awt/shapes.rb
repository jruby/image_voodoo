class ImageVoodoo
  module Shapes
    ##
    # *AWT* Draw a square
    #
    def square(x, y, dim, rgb, fill=true)
      square_rounded(x, y, dim, rgb, 0, fill)
    end

    ##
    # *AWT* Draw a rectangle
    #
    def rect(x, y, width, height, rgb, fill=true)
      rect_rounded(x, y, width, height, rgb, 0, 0, fill)
    end

    ##
    # *AWT* Draw a rounded square
    #
    def square_rounded(x, y, dim, rgb, arc_width=0, fill=true)
      rect_rounded(x,y, dim, dim, rgb, arc_width, arc_width, fill)
    end

    ##
    # *AWT* Draw a rounded rectangle
    #
    def rect_rounded(x, y, width, height, rgb, arc_width=0, arc_height=0, fill=true)
      as_color(ImageVoodoo.hex_to_color(rgb)) do |g|
        if fill
          g.fill_round_rect x, y, width, height, arc_width, arc_height
        else
          g.draw_round_rect x, y, width, height, arc_width, arc_height
        end
      end
    end

    def as_color(color)
      paint do |g|
        old_color = g.color
        g.color = color
        yield g
        g.color = old_color
      end
    end
  end
end

