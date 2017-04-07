require 'test/unit/testcase'
require 'test/unit' if $PROGRAM_NAME == __FILE__
require 'image_voodoo'

# Depends on a small portion of awt/shapes working properly
class TestImageVoodoo < Test::Unit::TestCase
  # 04
  # b8
  def make_square
    image = ImageVoodoo.new_image 20, 20, "test.gif"
    image.square(*ul, 10, '000000')
    image.square(*ur, 10, '444444')
    image.square(*ll, 10, '888888')
    image.square(*lr, 10, 'bbbbbb')
  end

  def assert_color(color, red, green, blue, alpha=nil)
    assert_equal(red, color.red)
    assert_equal(green, color.green)
    assert_equal(blue, color.blue)
    assert_equal(alpha, color.alpha) if alpha
  end

  def ul
    [0, 0]
  end

  def ur
    [10, 0]
  end

  def ll
    [0, 10]
  end

  def lr
    [10, 10]
  end

  # TODO: Don't fully know how to predict pixel values for adjust_brightness.

  def test_alpha
    image = make_square
    image = image.alpha('000000')
    assert_equal(0xff, image.color_at(0, 0).alpha)
  end
  
  # 04 -0-> 04 -90-> 80 -180-> 4b -270-> b8
  # 8b      8b       b4        08        40
  def test_rotate
    image = make_square
    assert_color(image.color_at(0, 0), 0x00, 0x00, 0x00)
    image = image.rotate(90)
    assert_color(image.color_at(0, 0), 0x88, 0x88, 0x88)
    image = image.rotate(180)
    assert_color(image.color_at(0, 0), 0x44, 0x44, 0x44)
    image = image.rotate(270)
    assert_color(image.color_at(0, 0), 0xbb, 0xbb, 0xbb)
  end

  # 04  -(-90)-> 4b -(-180)-> 80 -(-270)-> b8
  # 8b           08           b4           40
  def test_rotate_negative
    image = make_square
    image = image.rotate(-90)
    assert_color(image.color_at(0, 0), 0x44, 0x44, 0x44)
    image = image.rotate(-180)
    assert_color(image.color_at(0, 0), 0x88, 0x88, 0x88)
    image = image.rotate(-270)
    assert_color(image.color_at(0, 0), 0xbb, 0xbb, 0xbb)
  end
end
