#
# = ImageVoodoo
# == Description
#
# ImageVoodoo is an ImageScience-API-compatible image manipulation library for 
# JRuby.  
#
# == Examples
#
# === Simple block-based examples
#
#    ImageVoodoo.with_image(ARGV[0]) do |img|
#      img.cropped_thumbnail(100) { |img2| img2.save "CTH.jpg" }
#      img.with_crop(100, 200, 400, 600) { |img2| img2.save "CR.jpg" }
#      img.thumbnail(50) { |img2| img2.save "TH.jpg" }
#      img.resize(100, 150) do |img2|
#        img2.save "HEH.jpg"
#        img2.save "HEH.png"
#      end
#    end
#
# === Non-block return (not image_science compatible)
#
# img = ImageVoodoo.with_image(ARGV[0])
# negative_img = img.negative
#
class ImageVoodoo
  include Java

  import java.awt.RenderingHints
  import java.awt.color.ColorSpace
  import java.awt.geom.AffineTransform
  import java.awt.image.BufferedImage
  import java.awt.image.ByteLookupTable
  import java.awt.image.ColorConvertOp
  import java.awt.image.LookupOp
  import java.awt.image.RescaleOp
  JFile = java.io.File
  import java.io.ByteArrayInputStream
  import java.io.ByteArrayOutputStream
  import javax.imageio.ImageIO
  import javax.swing.JFrame

  NEGATIVE_OP = LookupOp.new(ByteLookupTable.new(0, (0...254).to_a.reverse.to_java(:byte)), nil)
  GREY_OP = ColorConvertOp.new(ColorSpace.getInstance(ColorSpace::CS_GRAY), nil)
  ARGB = BufferedImage::TYPE_INT_ARGB
  RGB = BufferedImage::TYPE_INT_RGB

  def initialize(src)
    @src = src
  end

  #
  # Add a border to the image and yield/return a new image.  The following
  # options are supported:
  #   - width: How thick is the border (default: 3)
  #   - color: Which color is the border (in rrggbb hex value) 
  #   - style: etched, raised, plain (default: plain)
  #
  def add_border(options = {})
    border_width = options[:width].to_i || 2
    color = hex_to_color(options[:color]) || hex_to_color("000000")
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

  #
  # Adjusts the brightness of each pixel in image by the following formula:
  # new_pixel = pixel * scale + offset
  #
  def adjust_brightness(scale, offset)
    image = internal_transform(RescaleOp.new(scale, offset, nil))
    block_given? ? yield(image) : image
  end

  #
  # Converts rgb hex color value to an alpha value an yields/returns the new 
  # image.
  #
  def alpha(rgb)
    color = hex_to_color(rgb)
    target = paint(BufferedImage.new(width, height, ARGB)) do |g|
      g.set_composite(java.awt.AlphaComposite::Src)
      g.draw_image(@src, nil, 0, 0)
      0.upto(height-1) do |i|
        0.upto(width-1) do |j|
          target.setRGB(j, i, 0x8F1C1C) if target.getRGB(j, i) == color.getRGB
        end
      end
    end
    block_given? ? yield(target) : target
  end

  # 
  # Write current image out as a stream of bytes using provided format.
  # 
  def bytes(format)
    out = ByteArrayOutputStream.new
    ImageIO.write(@src, format, out)
    String.from_java_bytes(out.to_byte_array)
  end

  #
  # Creates a square thumbnail of the image cropping the longest edge to 
  # match the shortest edge, resizes to size, and yields/returns the new image. 
  #
  def cropped_thumbnail(size)
    l, t, r, b, half = 0, 0, width, height, (width - height).abs / 2
    l, r = half, half + height if width > height
    t, b = half, half + width if height > width

    target = with_crop(l, t, r, b).thumbnail(size)
    block_given? ? yield(target) : target
  end

  #
  # Flips the image horizontally and yields/returns the new image.
  #
  def flip_horizontally
    target = paint do |g|
      g.draw_image @src, 0, 0, width, height, width, 0, 0, height, nil
    end
    block_given? ? yield(target) : target
  end

  #
  # Flips the image vertically and yields/returns the new image.
  #
  def flip_vertically
    target = paint do |g|
      g.draw_image @src, 0, 0, width, height, 0, height, width, 0, nil
    end
    block_given? ? yield(target) : target
  end

  # 
  # Creates a grayscale version of image and yields/returns the new image.
  #
  def greyscale
    target = internal_transform(GREY_OP)
    block_given? ? yield(target) : target
  end
  alias_method :grayscale, :greyscale

  # 
  # Creates a negative and yields/returns the new image.
  #
  def negative
    target = internal_transform(NEGATIVE_OP)
    block_given? ? yield(target) : target
  end

  #
  # Resizes the image to width and height using bicubic interpolation and 
  # yields/returns the new image. 
  #
  def resize(width, height)
    target = paint(BufferedImage.new(width, height, color_type)) do |g|
      g.set_rendering_hint(RenderingHints::KEY_INTERPOLATION,
                           RenderingHints::VALUE_INTERPOLATION_BICUBIC)
      h_scale, w_scale = height.to_f / @src.height, width.to_f / @src.width
      transform = AffineTransform.get_scale_instance w_scale, h_scale
      g.draw_rendered_image @src, transform
    end
    block_given? ? yield(target) : target
  rescue NativeException => ne
    raise ArgumentError, ne.message
  end

  # 
  # Saves the image out to path. Changing the file extension will convert 
  # the file type to the appropriate format. 
  #
  def save(file)
    format = File.extname(file)
    return false if format == ""
    format = format[1..-1].downcase
    ImageIO.write(@src, format, JFile.new(file))
    true
  end

  #
  # Resize (scale) the current image by the provided ratio and yield/return
  # the new image.
  #
  def scale(ratio)
    new_width, new_height = (width * ratio).to_i, (height * ratio).to_i
    target = resize(new_width, new_height)
    block_given? ? yield(target) : target
  end

  #
  # Creates a proportional thumbnail of the image scaled so its longest 
  # edge is resized to size and yields/returns the new image. 
  #
  def thumbnail(size)
    target = scale(size.to_f / (width > height ? width : height))
    block_given? ? yield(target) : target
  end

  #
  # Crops an image to left, top, right, and bottom and then yields/returns the 
  # new image. 
  #
  def with_crop(left, top, right, bottom)
    image = ImageVoodoo.new @src.get_subimage(left, top, right-left, bottom-top)
    block_given? ? yield(image) : image
  end

  # 
  # A simple swing wrapper around an image voodoo object.
  #
  class JImagePanel < javax.swing.JPanel
    def initialize(image, x=0, y=0)
      super()
      @image, @x, @y = image, x, y
    end

    def image=(image)
      @image = image
      invalidate
    end

    def getPreferredSize
      java.awt.Dimension.new(@image.width, @image.height)
    end

    def paintComponent(graphics)
      graphics.draw_image(@image.to_java, @x, @y, nil)
    end
  end

  # Internal class for closing preview window
  class WindowClosed
    def initialize(block = nil)
      @block = block || proc { java.lang.System.exit(0) }
    end
    def method_missing(meth,*args); end
    def windowClosing(event); @block.call; end
  end

  #
  # Creates a viewable frame displaying current image within it.
  #
  def preview(&block)
    frame = JFrame.new("Preview")
    frame.add_window_listener WindowClosed.new(block)
    frame.set_bounds 0, 0, width + 20, height + 40
    frame.add JImagePanel.new(self, 10, 10)
    frame.visible = true
  end

  #
  # TODO: Figure out how to determine whether source has alpha or not
  # Experimental: Read an image from the url source and yield/return that
  # image.
  #
  def self.from_url(source)
    url = java.net.URL.new(source)
    image = java.awt.Toolkit.default_toolkit.create_image(url)
    tracker = java.awt.MediaTracker.new(java.awt.Label.new(""))
    tracker.addImage(image, 0);
    tracker.waitForID(0)
    target = paint(BufferedImage.new(image.width, image.height, RGB)) do |g| 
      g.draw_image image, 0, 0, nil
    end
    block_given? ? yield(target) : target
  rescue java.io.IOException, java.net.MalformedURLException
    raise ArgumentError.new "Trouble retrieving image: #{$!.message}"
  end

  # 
  # A top-level image loader opens path and then yields/returns the image.
  #
  def self.with_image(file)
    raise ArgumentError, "file does not exist" unless File.file?(file)
    buffered_image = ImageIO.read(JFile.new(file))
    image = ImageVoodoo.new(buffered_image) if buffered_image
    image && block_given? ? yield(image) : image
  end

  # 
  # A top-level image loader reads bytes and then yields/returns the image.
  #
  def self.with_bytes(bytes)
    bytes = bytes.to_java_bytes if String === bytes
    image = ImageVoodoo.new ImageIO.read(ByteArrayInputStream.new(bytes))
    block_given? ? yield(image) : image
  end

  #
  # Returns the height of the image, in pixels. 
  #
  def height
    @src.height
  end

  #
  # Returns the width of the image, in pixels. 
  #
  def width
    @src.width
  end

  #
  # Returns the underlying Java BufferedImage associated with this object.
  #
  def to_java
    @src
  end

  private

  #
  # Converts a RGB hex value into a java.awt.Color object or dies trying
  # with an ArgumentError.
  #
  def hex_to_color(rgb)
    raise ArgumentError.new "hex rrggbb needed" if rgb !~ /[[:xdigit:]]{6,6}/

    java.awt.Color.new(rgb[0,2].to_i(16), rgb[2,2].to_i(16), rgb[4,2].to_i(16))
  end

  # 
  # Determines the best colorspace for a new image based on whether the
  # existing image contains an alpha channel or not.
  #
  def color_type
    @src.color_model.has_alpha ? ARGB : RGB
  end

  #
  # DRY up drawing setup+teardown
  # 
  def paint(src=dup_src)
    yield src.graphics
    src.graphics.dispose
    ImageVoodoo.new src
  end

  # 
  # Make a duplicate of the underlying Java src image
  #
  def dup_src
    BufferedImage.new width, height, color_type
  end

  #
  # Do simple AWT operation transformation to target.
  #
  def internal_transform(operation, target=dup_src)
    paint(target) do |g|
      g.draw_image(@src, 0, 0, nil)
      g.draw_image(operation.filter(target, nil), 0, 0, nil)
    end
  end
end
