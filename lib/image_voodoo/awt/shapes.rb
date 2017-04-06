class ImageVoodoo
  module Shapes
    # FIXME: Move and rewrite in terms of new shape
    ##
    # *AWT* (experimental) Add a border to the image and yield/return a new
    # image.  The following options are supported:
    #   - width: How thick is the border (default: 3)
    #   - color: Which color is the border (in rrggbb hex value)
    #   - style: etched, raised, plain (default: plain)
    #
    def add_border(options = {})
      border_width = options[:width].to_i || 2
      color = hex_to_color(options[:color]) || hex_to_color('000000')
      style = options[:style]
      style = nil if style.to_sym == :plain
      new_width, new_height = width + 2*border_width, height + 2*border_width
      target = paint(BufferedImage.new(new_width, new_height, color_type)) do |g|
        g.color = color
        if style
          raised = style.to_sym == :raised ? true : false
          g.fill3DRect(0, 0, new_width, new_height, raised)
        else
          g.fill_rect(0, 0, new_width, new_height)
        end
        g.draw_image(@src, nil, border_width, border_width)
      end
      block_given? ? yield(target) : target
    end

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
      rect_rounded(x, y, dim, dim, rgb, arc_width, arc_width, fill)
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
