# frozen_string_literal: true

# Before we load image_voodoo we can specify whether we want it to load full
# AWT ala http://www.oracle.com/technetwork/articles/javase/headless-136834.html
# Most users are using image_voodoo as a library for manipulation and do not
# want a full peer window popping up.
unless defined? ImageVoodoo::NEEDS_HEAD
  java.lang.System.set_property 'java.awt.headless', 'true'
end

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
class ImageVoodoo
  attr_writer :quality # used by quality(value)

  include Java

  JFile = java.io.File

  # FIXME: This has an issue when used in test/unit where the classcastexception
  #   is throwing the stack trace to output.  This does not happen when used
  #   directly.  Not sure....
  # gae and awt define the technology-specific methods and more importantly
  # all the *_impl methods which you will see referenced in this file.
  begin
    require 'image_voodoo/gae'
  rescue
    require 'image_voodoo/awt'
  end

  def initialize(io, src, format=nil)
    @io, @src, @format = io, src, format
    @quality = nil # nil means no specific quality ever specified
  end

  # Gets RGB value within the source image at [x, y].  If using AWT backend
  # then consider using color_at as this is a Java signed int value of an
  # unsigned value.
  def pixel(x, y)
    @src.getRGB(x, y)
  end

  # Adjusts the brightness of each pixel in image by the following formula:
  # new_pixel = pixel * scale + offset
  def adjust_brightness(scale, offset)
    image = guard { adjust_brightness_impl(scale, offset) }
    block_given? ? yield(image) : image
  end

  # Converts rgb hex color value to an alpha value an yields/returns the new
  # image.
  def alpha(rgb)
    target = guard { alpha_impl(rgb) }
    block_given? ? yield(target) : target
  end

  # Get current image bytes as a String using provided format. Format parameter
  # is the informal name of an image type - for instance,
  # "bmp" or "jpg". If the backend is AWT the types available are listed in
  # javax.imageio.ImageIO.getWriterFormatNames()
  def bytes(format)
    java_bytes = guard { bytes_impl(format) }
    String.from_java_bytes java_bytes
  end

  # If current image was taken by a phone it might save the orientation
  # in format it was physically taken and added IFD0 Orientation information
  # instead of rotating it.  This method will perform that rotation based
  # on Orientation metadata.
  def correct_orientation
    target = guard { correct_orientation_impl }
    block_given? ? yield(target) : target
  end

  # crops part of an image
  def crop(x, y, width, height)
    target = with_crop(x, y, x + width, y + height)
    block_given? ? yield(target) : target
  end

  # Creates a square thumbnail of the image cropping the longest edge to
  # match the shortest edge, resizes to size, and yields/returns the new image.
  def cropped_thumbnail(size)
    l, t, r, b = calculate_thumbnail_dimensions
    target = with_crop(l, t, r, b).thumbnail(size)
    block_given? ? yield(target) : target
  end

  private def calculate_thumbnail_dimensions
    half = (width - height).abs / 2
    if width > height
      [half, 0, half + height, height]
    else
      [0, half, width, half + width]
    end
  end

  # Flips the image horizontally and yields/returns the new image.
  def flip_horizontally
    target = guard { flip_horizontally_impl }
    block_given? ? yield(target) : target
  end

  # Flips the image vertically and yields/returns the new image.
  def flip_vertically
    target = guard { flip_vertically_impl }
    block_given? ? yield(target) : target
  end

  # Creates a grayscale version of image and yields/returns the new image.
  def greyscale
    target = guard { greyscale_impl }
    block_given? ? yield(target) : target
  end
  alias grayscale greyscale

  # Extracts metadata from an image.
  def metadata
    guard { metadata_impl }
  end

  # Creates a negative and yields/returns the new image.
  def negative
    target = guard { negative_impl }
    block_given? ? yield(target) : target
  end

  # Set quality you want resulting image to be once you save or extract
  # bytes for the image.  Note: This will only work for lossy image
  # formats like PNG of JPEG.  For others it will be ignored.
  def quality(amount)
    if amount < 0.0 || amount > 1.0
      raise ArgumentError, 'Quality must be between 0.0 and 1.0'
    end

    target = dup
    target.quality = amount
    block_given? ? yield(target) : target
  end

  # Resizes the image to width and height and yields/returns the new image.
  def resize(width, height)
    target = guard { resize_impl(width, height) }
    block_given? ? yield(target) : target
  rescue java.lang.Exception => e # figure out why this is here at all?
    raise ArgumentError, e.message
  end

  # Rotates the image by angle (specified in degrees).
  def rotate(angle)
    target = guard { rotate_impl(to_radians(angle)) }
    block_given? ? yield(target) : target
  end

  # Saves the image out to path. Changing the file extension will convert
  # the file type to the appropriate format.
  def save(file)
    format = File.extname(file)
    return false if format == ''

    format = format[1..-1].downcase
    guard { save_impl(format, JFile.new(file)) }
    true
  end

  # Resize (scale) the current image by the provided ratio and yield/return
  # the new image.
  def scale(ratio)
    new_width, new_height = (width * ratio).to_i, (height * ratio).to_i
    target = resize(new_width, new_height)
    block_given? ? yield(target) : target
  end

  # Creates a proportional thumbnail of the image scaled so its longest
  # edge is resized to size and yields/returns the new image.
  def thumbnail(size)
    target = scale(size.to_f / (width > height ? width : height))
    block_given? ? yield(target) : target
  end

  # Crops an image to left, top, right, and bottom and then yields/returns the
  # new image.
  def with_crop(left, top, right, bottom)
    image = guard { with_crop_impl(left, top, right, bottom) }
    block_given? ? yield(image) : image
  end

  # Creates a new (empty) image with a file name specified.
  def self.new_image(width, height, file_name)
    image = guard { new_image_impl(width, height, file_name) }
    block_given? ? yield(image) : image
  end

  # A top-level image loader opens path and then yields/returns the image.
  def self.with_image(path)
    raise ArgumentError, "file does not exist: #{path}" unless File.file?(path)

    image = guard { with_image_impl(JFile.new(path)) }
    image && block_given? ? yield(image) : image
  end

  # A top-level image loader reads bytes and then yields/returns the image.
  def self.with_bytes(bytes)
    bytes = bytes.to_java_bytes if bytes.is_a? String
    image = guard { with_bytes_impl(bytes) }
    block_given? ? yield(image) : image
  end

  class << self
    alias with_image_from_memory with_bytes
  end

  # *_impl providers only need provide the implementation if it can
  # support it.  Otherwise, this method will detect that the method is
  # missing.
  def self.guard(&block)
    block.call
  rescue NoMethodError => e
    "Unimplemented Feature: #{e}"
  end

  def guard(&block)
    ImageVoodoo.guard(&block)
  end

  # Returns the height of the image, in pixels.
  def height
    @src.height
  end

  # Returns the width of the image, in pixels.
  def width
    @src.width
  end

  # Returns the underlying Java class associated with this object. Note:
  # Depending on whether you are using AWT or GAE/J you will get a totally
  # different Java class.  So caveat emptor!
  def to_java
    @src
  end

  # Returns detected image format from binary representation of input data
  # as upper case string. Eg. JPEG, BMP, PNG. For GWT image representation
  # compatibility method name is :format. It also accepts block and returns
  # format as first block argument. When format not detected or not set it
  # returns nil
  def format
    @format && block_given? ? yield(@format) : @format
  end

  def to_radians(degrees)
    degrees * Math::PI / 180
  end
end
