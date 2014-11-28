# Used to generate part of metadata.rb.  Unfortunately, I am unable to fill
# in appropriate access methods so I generate with get_string and then manually
# update.  In future versions I will just run this twice with old and new src
# and manually splice in new data (or fixes).
# 
# % find ../metadata-extractor/Source/ -name '*Directory.java' | xargs grep TAG_ | grep 'public static final' | ruby tools/gen.rb

def normalize_directory_name(path)
  path.gsub('/', '.')
end

def normalize_tag_name(capname)
  name = capname.split('_').map {|e| e.capitalize }.join(' ')
  [name, "TAG_#{capname}"]
end

# 'ExifSubIFDDirectory' => 'Exif Sub IFD0'
def humanize_directory_name(s)
  s = s.gsub('Directory', '')
  s.split(/([A-Z]+[a-z]+)/).map {|a| a == "" ? nil : a }.compact.join(' ')
end

io = $stdin
directories = {}

io.readlines.each do |line|
  #  .../IptcDirectory.java: public static final int TAG_BY_LINE = 80;
  if %r{Source/[/]?(?<directory_name>.*).java:.*TAG_(?<tag_name>[\S]+)} =~ line
    directory_name = normalize_directory_name directory_name
    directories[directory_name] ||= []
    directories[directory_name] << normalize_tag_name(tag_name)
  end
end

directories.each do |directory, tag_names|
  class_name = directory.split('.')[-1]
  puts "class #{class_name} < Directory"
  puts "  java_import #{directory}"
  puts ""
  puts "  def self.directory_class"
  puts "    #{directory}"
  puts "  end"
  puts ""
  puts "  TAGS = {"
  tag_names.each do |name, original_name|
    puts "    '#{name}' => ['#{original_name}', :get_string],"
  end
  puts "  }"
  puts "end"
  puts ""
end

puts ""
puts "DIRECTORY_MAP = {"
directories.each do |directory, _|
  class_name = directory.split('.')[-1]
  puts "  '#{humanize_directory_name(class_name)}' => #{class_name},"
end
puts "}"
  

