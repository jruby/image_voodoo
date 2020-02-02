# frozen_string_literal: true

require 'image_voodoo/awt/core_ext/buffered_image'
require 'image_voodoo/awt/core_ext/graphics2d'
require 'image_voodoo/awt/shapes'

# AWT Implementation
class ImageVoodoo
  include ImageVoodoo::Shapes

  java_import java.awt.AlphaComposite
  java_import java.awt.Color
  java_import java.awt.Label
  java_import java.awt.MediaTracker
  java_import java.awt.RenderingHints
  java_import java.awt.Toolkit
  java_import java.awt.color.ColorSpace
  java_import java.awt.event.WindowAdapter
  java_import java.awt.geom.AffineTransform
  java_import java.awt.image.ShortLookupTable
  java_import java.awt.image.ColorConvertOp
  java_import java.awt.image.LookupOp
  java_import java.awt.image.RescaleOp
  java_import java.io.ByteArrayInputStream
  java_import java.io.ByteArrayOutputStream
  java_import java.io.IOException
  java_import java.net.MalformedURLException
  java_import java.net.URL
  java_import javax.imageio.ImageIO
  java_import javax.imageio.IIOImage
  java_import javax.imageio.ImageWriteParam
  java_import javax.imageio.stream.FileImageOutputStream
  java_import javax.swing.JFrame
  java_import javax.imageio.IIOException

  # A simple swing wrapper around an image voodoo object.
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

  ImageVoodoo::JImagePanel.__persistent__ = true

  # Internal class for closing preview window
  class WindowClosed < WindowAdapter
    def initialize(block = nil)
      @block = block || proc { java.lang.System.exit(0) }
      super()
    end

    def windowClosing(_)
      @block.call
    end
  end

  # *AWT-only* Return awt Color object.
  def color_at(x, y)
    Color.new(pixel(x, y))
  end

  # *AWT-only* Creates a viewable frame displaying current image within it.
  def preview(&block)
    frame = JFrame.new('Preview')
    frame.add_window_listener WindowClosed.new(block)
    frame.set_bounds 0, 0, width + 20, height + 40
    frame.add JImagePanel.new(self, 10, 10)
    frame.visible = true
  end

  # *AWT-only* paint/render to the source
  def paint(src=dup_src)
    yield src.graphics, src
    src.graphics.dispose
    ImageVoodoo.new(@io, src, @format)
  end

  # TODO: Figure out how to determine whether source has alpha or not
  # Experimental: Read an image from the url source and yield/return that image.
  def self.from_url(source)
    image = image_from_url source
    target = paint(BufferedImage.new(image.width, image.height, RGB)) do |g|
      g.draw_image image, 0, 0, nil
    end
    block_given? ? yield(target) : target
  end

  def self.image_from_url(source)
    image = Toolkit.default_toolkit.create_image(URL.new(source))
    tracker = MediaTracker.new(Label.new(''))
    tracker.addImage(image, 0)
    tracker.waitForID(0)
    image
  rescue IOException, MalformedURLException
    raise ArgumentError, "Trouble retrieving image: #{$!.message}"
  end

  # *AWT-only* Create an image of width x height filled with a single color.
  def self.canvas(width, height, rgb='000000')
    image = ImageVoodoo.new(@io, BufferedImage.new(width, height, ARGB))
    image.rect(0, 0, width, height, rgb)
  end

  class << self
    private

    def detect_format_from_input(input)
      stream = ImageIO.createImageInputStream(input)
      readers = ImageIO.getImageReaders(stream)
      readers.has_next ? readers.next.format_name.upcase : nil
    end

    # FIXME: use library to figure this out
    def determine_image_type_from_ext(ext)
      case ext
      when 'jpg' then RGB
      else ARGB
      end
    end

    def determine_format_from_file_name(file_name)
      ext = file_name.split('.')[-1]

      raise ArgumentError, "no extension in file name #{file_name}" unless ext

      ext
    end

    def new_image_impl(width, height, file_name)
      format = determine_format_from_file_name file_name
      image_type = determine_image_type_from_ext format
      buffered_image = BufferedImage.new width, height, image_type
      ImageVoodoo.new file_name, buffered_image, format
    end

    def read_image_from_input(input)
      ImageIO.read(input)
    rescue IIOException
      require 'CMYKDemo.jar'
      jpeg = org.monte.media.jpeg

      cmyk_reader = jpeg.CMYKJPEGImageReader.new jpeg.CMYKJPEGImageReaderSpi.new
      cmyk_reader.input = ImageIO.createImageInputStream(input)
      cmyk_reader.read 0
    end

    def with_bytes_impl(bytes)
      input_stream = ByteArrayInputStream.new(bytes)
      format = detect_format_from_input(input_stream)
      input_stream.reset
      buffered_image = read_image_from_input(input_stream)
      input_stream.reset
      ImageVoodoo.new(input_stream, buffered_image, format)
    end

    def with_image_impl(file)
      format = detect_format_from_input(file)
      buffered_image = read_image_from_input(file)
      buffered_image ? ImageVoodoo.new(file, buffered_image, format) : nil
    end
  end

  # Save using the format string (jpg, gif, etc..) to the open Java File
  # instance passed in.
  def save_impl(format, file)
    write_new_image format, FileImageOutputStream.new(file)
  end

  private

  # Converts a RGB hex value into a java.awt.Color object or dies trying
  # with an ArgumentError.
  def hex_to_color(rgb='000000')
    rgb ||= '000000'

    raise ArgumentError, 'hex rrggbb needed' if rgb !~ /[[:xdigit:]]{6,6}/

    Color.new(rgb[0, 2].to_i(16), rgb[2, 2].to_i(16), rgb[4, 2].to_i(16))
  end

  NEGATIVE_OP = LookupOp.new(ShortLookupTable.new(0, (0...256).to_a.reverse.to_java(:short)), nil)
  GREY_OP = ColorConvertOp.new(ColorSpace.getInstance(ColorSpace::CS_GRAY), nil)
  ARGB = BufferedImage::TYPE_INT_ARGB
  RGB = BufferedImage::TYPE_INT_RGB
  SCALE_SMOOTH = java.awt.Image::SCALE_SMOOTH

  # Determines the best colorspace for a new image based on whether the
  # existing image contains an alpha channel or not.
  def color_type
    @src.color_model.has_alpha ? ARGB : RGB
  end

  # Make a duplicate of the underlying Java src image
  def dup_src
    BufferedImage.new to_java.color_model, to_java.raster, true, nil
  end

  def src_without_alpha
    if @src.color_model.has_alpha
      img = BufferedImage.new(width, height, RGB)
      img.graphics.draw_image(@src, 0, 0, nil)
      img.graphics.dispose
      img
    else
      @src
    end
  end

  # Do simple AWT operation transformation to target.
  def transform(operation, target=dup_src)
    paint(target) do |g|
      g.draw_image(@src, 0, 0, nil)
      g.draw_image(operation.filter(target, nil), 0, 0, nil)
    end
  end

  def adjust_brightness_impl(scale, offset)
    transform(RescaleOp.new(scale, offset, nil))
  end

  def alpha_impl(rgb)
    color = hex_to_color(rgb).getRGB
    paint(BufferedImage.new(width, height, ARGB)) do |g, target|
      g.set_composite AlphaComposite::Src
      g.draw_image(@src, nil, 0, 0)
      target.each do |i, j|
        target.setRGB(i, j, 0x8F1C1C) if target.getRGB(i, j) == color
      end
    end
  end

  def bytes_impl(format)
    ByteArrayOutputStream.new.tap do |out|
      write_new_image format, ImageIO.create_image_output_stream(out)
    end.to_byte_array
  end

  def correct_orientation_impl
    case metadata.orientation
    when 2 then flip_horizontally
    when 3 then rotate(180)
    when 4 then flip_vertically
    when 5 then flip_horizontally && rotate(90)
    when 6 then rotate(90)
    when 7 then flip_horizontally && rotate(270)
    when 8 then rotate(270)
    else self
    end
  end

  def flip_horizontally_impl
    paint do |g|
      g.draw_image @src, 0, 0, width, height, width, 0, 0, height, nil
    end
  end

  def flip_vertically_impl
    paint do |g|
      g.draw_image @src, 0, 0, width, height, 0, height, width, 0, nil
    end
  end

  def greyscale_impl
    transform(GREY_OP)
  end

  def metadata_impl
    require 'image_voodoo/metadata'

    @metadata ||= ImageVoodoo::Metadata.new(@io)
  end

  def negative_impl
    transform(NEGATIVE_OP)
  end

  def resize_impl(width, height)
    paint_new_buffered_image(width, height) do |g|
      g.draw_this_image(@src.get_scaled_instance(width, height, SCALE_SMOOTH))
    end
  end

  def rotate_impl(radians)
    new_width, new_height = rotate_new_dimensions(radians)
    paint_new_buffered_image(new_width, new_height) do |g|
      g.translate (new_width - width) / 2, (new_height - height) / 2
      g.rotate radians, width / 2, height / 2
      g.draw_this_image @src
    end
  end

  def paint_new_buffered_image(width, height, color = color_type, &block)
    paint BufferedImage.new(width, height, color), &block
  end

  def rotate_new_dimensions(radians)
    sin, cos = Math.sin(radians).abs, Math.cos(radians).abs
    [(width * cos + height * sin).floor, (width * sin + height * cos).floor]
  end

  def with_crop_impl(left, top, right, bottom)
    ImageVoodoo.new(@io, @src.get_subimage(left, top, right-left, bottom-top), @format)
  end

  def write_new_image(format, stream)
    writer = ImageIO.getImageWritersByFormatName(format).next
    writer.output = stream

    param = writer.default_write_param
    if param.can_write_compressed && @quality
      param.compression_mode = ImageWriteParam::MODE_EXPLICIT
      param.compression_type ||= param.compression_types.first
      param.compression_quality = @quality
    end

    src = format.downcase == 'jpg' ? src_without_alpha : @src
    writer.write nil, IIOImage.new(src, nil, nil), param
  end
end
