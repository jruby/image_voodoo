# frozen_string_literal: true

require 'image_voodoo/needs_head'
require 'image_voodoo'

ImageVoodoo.with_image(ARGV[0], &:preview)
