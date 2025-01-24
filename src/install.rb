require "zip"
require "json"
require "nokogiri"
require "toml"
require "date"

require_relative "common"

def install_cmd
  check_requirements!

  mod_data = get_json_data("mod-data.json")
  config = get_toml_config

  make_modsettings_backup(config)

  Dir.glob(File.join(MODS_DIR, "*.zip")).each do |zip_file_name|
    puts "==== Processing #{zip_file_name} ===="
    mod_name = /#{MODS_DIR}\/([\w\s\-\._'"]+)\.zip/.match(zip_file_name)[1]

    if mod_name.nil?
      raise "Couldn't get mod name from zip file. Perhaps there are some unrecognized characters."
    end

    safe_mkdir(File.join(DUMP_DIR, mod_name))

    extract_mod_files(zip_file_name, mod_name)

    if File.exist?(File.join(DUMP_DIR, mod_name, "info.json"))
      info_json = get_json_data(File.join(DUMP_DIR, mod_name, "info.json"))

      check_info_json_fields!(info_json)

      if mod_data.dig(info_json["Mods"][0]["UUID"], "is_installed")
        puts "Mod is marked as installed. Skipping."
        next
      end

      insert_into_modsettings(info_json)

      update_mod_data(mod_data, info_json)
    end

    # TODO: Move .pak file
  end
end

def check_requirements!
  if !File.exist?("mod-data.json")
    raise "mod-data.json does not exist. Make sure to run the 'init' command."
  end
end

def get_toml_config
  if !File.exist?("conf.toml")
    raise "No conf.toml found. Make sure to run the 'init' command."
  end

  TOML.load_file("conf.toml")
end

def extract_mod_files(zip_file_name, mod_name)
  if File.exist?(File.join(DUMP_DIR, mod_name))
    puts "Zip file already extracted. Skipping."
    return
  end

  Zip::File.open(zip_file_name) do |zip_file|
    zip_file.each do |entry|
      filepath = File.join(DUMP_DIR, mod_name, entry.name)
      zip_file.extract(entry, filepath) { true }
    end
  end

  puts "Extracted zip file."
end

def insert_into_modsettings(info_json)
  xml_doc = get_xml_data(File.join("test-dest", "modsettings.lsx"))
  uuid = info_json["Mods"][0]["UUID"]

  if xml_doc.at("attribute#UUID[value='#{uuid}']")
    puts "WARN: Mod entry already exists in modsettings.lsx."
    return
  end

  builder = Nokogiri::XML::Builder.with(xml_doc.at("node#Mods children")) do |xml|
    xml.node.ModuleShortDesc! {
      xml.attribute.Folder!(type: "LSString", value: info_json["Mods"][0]["Folder"])
      xml.attribute.MD5!(type:"LSString", value: info_json["MD5"])
      xml.attribute.Name!(type: "LSString", value: info_json["Mods"][0]["Name"])
      xml.attribute.UUID!(type: "guid", value: uuid)
      xml.attribute.Version64!(type: "int64", value: info_json.dig("Mods", 0, "Version"))
    }
  end

  File.open(File.join("test-dest", "modsettings.lsx"), "w") do |f|
    f.write(builder.to_xml)
  end

  puts "Wrote data to modsettings.lsx."
end

def check_info_json_fields!(info_json)
  uuid = info_json.dig("Mods", 0, "UUID")
  folder = info_json.dig("Mods", 0, "Folder")
  name = info_json.dig("Mods", 0, "Name")

  if uuid.nil?
    raise "info.json does not have UUID. Cannot proceed."
  end

  if folder.nil?
    raise "info.json does not have Folder. Cannot proceed."
  end

  if name.nil?
    raise "info.json does not have Name. Cannot proceed."
  end
end

def update_mod_data(mod_data, info_json)
  uuid = info_json["Mods"][0]["UUID"]
  name = info_json["Mods"][0]["Name"]

  if mod_data[uuid]
    mod_data[uuid]["is_installed"] = true
  else
    new_number =
      if mod_data.values.size == 0
        1
      else
        mod_data.values.map { |mod| mod["number"] }.max + 1
      end
    mod_data[uuid] = {
      "is_installed" => true,
      "mod_name" => name,
      "uuid" => uuid,
      "number" => new_number,
      "created_at" => Time.now.to_s,
      "updated_at" => Time.now.to_s
    }
  end

  save_json_data("mod-data.json", mod_data)
end

def make_modsettings_backup(config)
  FileUtils.cd(modsettings_dir(config)) do
    return if File.exist?("modsettings.lsx.bak")

    FileUtils.cp("modsettings.lsx", "modsettings.lsx.bak")

    puts "Made backup of modsettings.lsx file."
  end
end

def modsettings_dir(config)
  File.join(config["paths"]["appdata_dir"], "PlayerProfiles", "Public")
end
