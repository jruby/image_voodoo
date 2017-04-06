#!/usr/local/bin/ruby -w

require 'benchmark'
require 'rbconfig'
require 'rubygems'
require 'image_science'

max = (ARGV.shift || 100).to_i
ext = ARGV.shift || 'png'
file = "blah_big.#{ext}"

unless File.exist?(file)
  if RbConfig::CONFIG['host_os'] =~ /darwin/i
    puts 'taking screenshot for thumbnailing benchmarks'
    system "screencapture -SC #{file}"
  elsif RbConfig::CONFIG['host_os'] =~ /linux/i
    puts 'taking screenshot for thumbnailing benchmarks'
    system "gnome-screenshot -f #{file}"
  else
    abort "You need to save an image to #{file} since we cannot generate one"
  end
end

if ext != 'png'
  ImageScience.with_image(file.sub(/#{ext}$/, 'png')) { |img| img.save(file) }
end

puts "# of iterations = #{max}"
Benchmark::bm(20) do |x|
  x.report('null_time') {
    max.times do
    end
  }

  x.report('cropped') {
    max.times do
      ImageScience.with_image(file) do |img|
        img.cropped_thumbnail(100) do |thumb|
          thumb.save("blah_cropped.#{ext}")
        end
      end
    end
  }

  x.report('proportional') {
    max.times do
      ImageScience.with_image(file) do |img|
        img.thumbnail(100) do |thumb|
          thumb.save("blah_thumb.#{ext}")
        end
      end
    end
  }

  x.report('resize') {
    max.times do
      ImageScience.with_image(file) do |img|
        img.resize(200, 200) do |resize|
          resize.save("blah_resize.#{ext}")
        end
      end
    end
  }
end

# File.unlink(*Dir["blah*#{ext}"])
