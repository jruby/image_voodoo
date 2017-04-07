require 'test/unit/testcase'
require 'test/unit' if $PROGRAM_NAME == __FILE__
require 'image_voodoo'

class TestShapes < Test::Unit::TestCase
  def test_new_image
    image = ImageVoodoo.new_image 10, 20, "test.gif"
    assert_equal 10, image.width
    assert_equal 20, image.height
    assert_equal "gif", image.format
  end

  def test_square
    image = ImageVoodoo.new_image 10, 10, "test.gif"
    image.square 0, 0, 10, 'ff9900'
    color = image.color_at(0, 0)
    assert_equal(0xff, color.red)
    assert_equal(0x99, color.green)
    assert_equal(0x00, color.blue)
  end
end
