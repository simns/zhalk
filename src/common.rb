require "fileutils"

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

def safe_open_json(filename)
  data = nil
  if File.exist?(filename)
    File.open(filename) do |file|
      data = JSON.load(file)
    end
  end

  return data
end

def get_json_data(filename)
  file = File.open(filename)
  json_data = JSON.load(file)
  file.close()
  return json_data
end
