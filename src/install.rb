require "zip"
require "json"

require_relative "common"

def install_cmd
  check_requirements!

  mod_data = get_mod_data

  Dir.glob(File.join(MODS_DIR, "*.zip")).each do |zip_file_name|
    puts "==== Processing #{zip_file_name} ===="
    mod_name = /mods\/([\w\s\-\._'"]+)\.zip/.match(zip_file_name)[1]

    if mod_name.nil?
      raise "Couldn't get mod name from zip file. Perhaps there are some unrecognized characters."
    end

    if mod_data.dig(mod_name, "is_installed")
      puts "Mod is marked as installed. Skipping."
    end

    safe_mkdir(File.join(DUMP_DIR, mod_name))

    Zip::File.open(zip_file_name) do |zip_file|
      zip_file.each do |entry|
        filepath = File.join(DUMP_DIR, mod_name, entry.name)
        zip_file.extract(entry, filepath) { true }
      end
    end
  end
end

def check_requirements!
  if !File.exist?("mod-data.json")
    raise "mod-data.json does not exist. Make sure to run the 'init' command."
  end
end

def get_mod_data
  file = File.open("mod-data.json")
  json_data = JSON.load(file)
  file.close()
  return json_data
end
