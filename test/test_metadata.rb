require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__
require 'image_voodoo'

IMAGE_DIR = File.join File.dirname(__FILE__), '..', '..', 'metadata-extractor-images'

# FIXME: If we end up running on travis or other tool this should be ignored
# subdir to this project and probably clone repo into that subdir
unless File.exist? IMAGE_DIR
  puts "To run this test you must clone: https://github.com/drewnoakes/metadata-extractor-images.git into a sibling directory to image_voodoo"
else
  class TestImageVoodooMetadata < Test::Unit::TestCase
    def setup
      @path = File.join IMAGE_DIR, "Apple iPhone 4S.jpg"
      @path_gps = File.join IMAGE_DIR, "Apple iPhone 4.jpg"
      @path_no_exif = File.join File.dirname(__FILE__), "pix.png"
    end
    def test_metadata_from_file
      ImageVoodoo.with_image @path do |img|
        assert img.metadata[:IFD0].exists?
        assert_equal 6, img.metadata[:IFD0][:Orientation]
        assert_equal 6, img.metadata.orientation
        assert_equal 3264, img.metadata.width
        assert_equal 2448, img.metadata.height
        assert_equal "Apple", img.metadata.make
        assert_equal "iPhone 4S", img.metadata.model
      end
    end

    def test_metadata_from_inputstream
      ImageVoodoo.with_bytes File.read(@path) do |img|
        assert_equal(6, img.metadata[:IFD0][:Orientation])
      end
    end

    def test_metadata_no_ifd0
      ImageVoodoo.with_image @path_no_exif do |img|
        assert !img.metadata[:IFD0].exists?
        assert_equal(nil, img.metadata[:IFD0][:Orientation])
      end
    end

    def test_metadata_gps
      ImageVoodoo.with_image @path_gps do |img|
        assert img.metadata[:Gps].exists?
        assert_equal("N", img.metadata[:Gps]['Latitude Ref'])
      end
    end
  end
end
