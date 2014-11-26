require 'metadata-extractor-2.6.2.jar'

class ImageVoodoo
  # FIXME: Add more image types and any other missing directory types.
  # Uses class references in metadata-extractor.  Let's keep a map...
  DIRNAME_MAP = {
    'Jpeg' => com.drew.metadata.jpeg.JpegDirectory,
    'Exif SubIFD' => com.drew.metadata.exif.ExifSubIFDDirectory,
    'Exif IFD0' => com.drew.metadata.exif.ExifIFD0Directory,
    'SubIFD' => com.drew.metadata.exif.ExifSubIFDDirectory,
    'IFD0' => com.drew.metadata.exif.ExifIFD0Directory,
    'GPS' => com.drew.metadata.exif.GpsDirectory,
    'Exif Thumbnail' => com.drew.metadata.exif.ExifThumbnailDirectory,
    'Thumbnail' => com.drew.metadata.exif.ExifThumbnailDirectory,
  }
  
  class Metadata
    def initialize(io)
      @metadata = com.drew.imaging.ImageMetadataReader.read_metadata io
    end

    def [](dirname)
      dirclass = DIRNAME_MAP[dirname.to_s] || dirname.to_s
      raise ArgumentError.new "Uknown metadata group: #{dirname}" unless dirclass
      directory = @metadata.get_directory dirclass.java_class
      ImageVoodoo::Directory.new directory
    end
  end

  class Directory
    java_import com.drew.metadata.exif.ExifIFD0Directory
    
    # Optimistically hoping all tags are uniquely named across named
    # groups.  If not then this will either need namespacing or one
    # map per group.
    TAG_MAP = {
      'Orientation' => [ExifIFD0Directory::TAG_ORIENTATION, :get_int],
    }
    def initialize(directory)
      @directory = directory
    end

    ##
    # Return tag value for the tag specified or nil if there is none
    # defined.
    def [](tag_name)
      (tag_type, tag_method) = TAG_MAP[tag_name.to_s] || tag_name
      raise ArgumentError.new "Unkown tag_name: #{tag_name}" unless tag_type
      return nil unless @directory.contains_tag tag_type
      @directory.__send__ tag_method, tag_type
    end
  end
end
