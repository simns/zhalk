require "fileutils"
require "nokogiri"
require "json"
require "toml"

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
  updated_dest = dest
  basename = File.basename(src)
  if File.directory?(dest)
    updated_dest = File.join(dest, basename)
  end

  if !File.exist?(updated_dest)
    FileUtils.cp(src, updated_dest)
    puts "Created file #{File.basename(updated_dest)}." if with_logging
    return true
  else
    puts "File #{File.basename(updated_dest)} already exists." if with_logging
    return false
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

def modsettings_dir(config = nil)
  config = get_toml_config if config.nil?

  File.join(config["paths"]["appdata_dir"], "PlayerProfiles", "Public")
end

def get_modsettings
  config = get_toml_config

  get_xml_data(File.join(modsettings_dir(config), "modsettings.lsx"))
end

def get_toml_config
  TOML.load_file("conf.toml")
end

def num_mods(num, type)
  num == 1 ? "1 #{type} mod" : "#{num} #{type} mods"
end

def check_requirements!
  if !File.exist?("mod-data.json")
    raise "mod-data.json does not exist. Make sure to run the 'init' command."
  end
  if !File.exist?("conf.toml")
    raise "No conf.toml found. Make sure to run the 'init' command."
  end
end
