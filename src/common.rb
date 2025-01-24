require "fileutils"
require "nokogiri"

MODS_DIR = "mods"
DUMP_DIR = "dump"

def safe_mkdir(name, with_logging: false)
  if !Dir.exist?(name)
    Dir.mkdir(name)
    puts "Created dir \"#{name}\"." if with_logging
  else
    puts "Dir \"#{name}\" already exists." if with_logging
  end
end

def safe_cp(src, dest, with_logging: false)
  if !File.exist?(dest)
    FileUtils.cp(src, dest)
    puts "Created file #{dest}." if with_logging
  else
    puts "File #{dest} already exists." if with_logging
  end
end

def safe_create(filename, content: "", with_logging: false)
  if !File.exist?(filename)
    File.write(filename, content)
    puts "Created file #{filename}." if with_logging
  else
    puts "File #{filename} already exists." if with_logging
  end
end

def get_json_data(filename)
  File.open(filename) do |file|
    return JSON.load(file)
  end
end

def save_json_data(filename, hash)
  File.open(filename, "w") do |file|
    file.write(hash.to_json)
  end
end

def get_xml_data(filename)
  File.open(filename) do |file|
    return Nokogiri::XML(file, &:noblanks)
  end
end
