class ImageVoodoo
  java_import com.google.appengine.api.images.Image
  java_import com.google.appengine.api.images.ImagesService
  java_import com.google.appengine.api.images.ImagesServiceFactory
  java_import com.google.appengine.api.images.Transform

  ImageService = ImagesServiceFactory.images_service

  #--
  # Value Add methods for this backend
  #++

  #Automatically adjust contrast and color levels.
  #GAE only.
  def i_am_feeling_lucky
    transform(ImagesServiceFactory.make_im_feeling_lucky)
  end

  #--
  # Implementations of standard features
  #++
  
  def flip_horizontally_impl
    transform(ImagesServiceFactory.make_horizontal_flip)
  end

  def flip_vertically_impl
    transform(ImagesServiceFactory.make_vertical_flip)
  end

  def resize_impl(width, height)
    transform(ImagesServiceFactory.make_resize(width, height))
  end

  def with_crop_impl(left, top, right, bottom)
    transform(ImagesServiceFactory.make_crop(left, top, right, bottom))
  end

  def self.with_bytes_impl(bytes)
    ImageVoodoo.new ImageServicesFactory.make_image(bytes)
  end

  private

  def from_java_bytes
    String.from_java_bytes @src.image_data
  end

  # 
  # Make a duplicate of the underlying src image
  #
  def dup_src
    ImageServicesFactory.make_image(from_java_bytes)
  end

  def transform(transform, target=dup_src)
    ImageService.apply_transform(transform, target)
  end
end
