require 'test/unit/testcase'
require 'test/unit' if $PROGRAM_NAME == __FILE__
require 'image_voodoo'

IMAGE_DIR = File.join File.dirname(__FILE__), '..', '..', 'metadata-extractor-images'

# FIXME: If we end up running on travis or other tool this should be ignored
# subdir to this project and probably clone repo into that subdir
if !File.exist? IMAGE_DIR
  puts 'To run this test you must clone:'
  puts 'https://github.com/drewnoakes/metadata-extractor-images.git'
  puts 'into a sibling directory to image_voodoo'
else
  class TestImageVoodooMetadata < Test::Unit::TestCase
    def setup
      @path = File.join IMAGE_DIR, 'jpg', 'Apple iPhone 4S.jpg'
      @path_gps = File.join IMAGE_DIR, 'jpg', 'Apple iPhone 4.jpg'
      @path_no_exif = File.join File.dirname(__FILE__), 'pix.png'
    end

    def assert_orientation(expected, metadata)
      assert_equal expected, metadata[:IFD0][:Orientation]
    end

    def test_metadata_from_file
      ImageVoodoo.with_image @path do |img|
        metadata = img.metadata
        assert_orientation 6, metadata
        assert_equal 6, metadata.orientation
        assert_equal 3264, metadata.width
        assert_equal 2448, metadata.height
        assert_equal 'Apple', metadata.make
        assert_equal 'iPhone 4S', metadata.model
      end
    end

    def test_metadata_from_inputstream
      ImageVoodoo.with_bytes File.read(@path) do |img|
        assert_orientation 6, img.metadata
      end
    end

    def test_metadata_no_ifd0
      ImageVoodoo.with_image @path_no_exif do |img|
        assert !img.metadata[:IFD0].exists?
        assert_orientation nil, img.metadata
      end
    end

    def test_metadata_gps
      ImageVoodoo.with_image @path_gps do |img|
        assert img.metadata[:Gps].exists?
        assert_equal('N', img.metadata[:Gps]['Latitude Ref'])
      end
    end

    def test_metadata_to_s
      ImageVoodoo.with_image @path do |img|
        assert img.metadata.to_s =~ /Make = Apple/
      end
    end
  end
end
