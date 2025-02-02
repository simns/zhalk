require "zip"
require "nokogiri"

require_relative "base_cmd"
require_relative "helpers/info_json_helper"
require_relative "helpers/constants"

class InstallCmd < BaseCmd
  def run
    self.make_modsettings_backup

    installed_mods = []

    Dir.glob(File.join(Constants::MODS_DIR, "*.zip")).each do |zip_file_name|
      puts "==== Processing #{zip_file_name} ===="
      mod_name = /#{Constants::MODS_DIR}\/([\w\s\-\._'"]+)\.zip/.match(zip_file_name)[1]

      if mod_name.nil?
        raise "Couldn't get mod name from zip file. Perhaps there are some unrecognized characters."
      end

      self.extract_mod_files(zip_file_name, mod_name)

      info_json_helper = InfoJsonHelper.new(mod_name)

      if info_json_helper.file_present?
        info_json_helper.load_data
        info_json_helper.check_fields!

        if @mod_data_helper.data.dig(info_json_helper.uuid, "is_installed")
          puts "Mod is marked as installed. Skipping."
          next
        end

        self.insert_into_modsettings(info_json_helper)

        self.update_mod_data(info_json_helper)

        self.copy_pak_files(mod_name)

        installed_mods << {
          name: mod_name,
          type: :standard
        }
      else
        did_copy = self.copy_pak_files(mod_name)

        if did_copy
          installed_mods << {
            name: mod_name,
            type: :pak_only
          }
        end
      end
    end

    self.print_install_report(installed_mods)
  end

  def extract_mod_files(zip_file_name, mod_name)
    if File.exist?(File.join(Constants::DUMP_DIR, mod_name))
      puts "Zip file already extracted. Skipping."
      return
    end

    self.safe_mkdir(File.join(Constants::DUMP_DIR, mod_name))

    puts "Extracting..."

    Zip::File.open(zip_file_name) do |zip_file|
      zip_file.each do |entry|
        filepath = File.join(Constants::DUMP_DIR, mod_name, entry.name)
        zip_file.extract(entry, filepath) { true }
      end
    end

    puts "Successfully extracted zip file."
  end

  def insert_into_modsettings(info_json_helper)
    modsettings = @modsettings_helper.data

    if modsettings.at("attribute#UUID[value='#{info_json_helper.uuid}']")
      puts "WARN: Mod entry already exists in modsettings.lsx."
      return
    end

    builder = Nokogiri::XML::Builder.with(modsettings.at("node#Mods children")) do |xml|
      xml.node.ModuleShortDesc! {
        xml.attribute.Folder!(type: "LSString", value: info_json_helper.folder)
        xml.attribute.MD5!(type: "LSString", value: info_json_helper.md5)
        xml.attribute.Name!(type: "LSString", value: info_json_helper.name)
        xml.attribute.UUID!(type: "guid", value: info_json_helper.uuid)
        xml.attribute.Version64!(type: "int64", value: info_json_helper.version)
      }
    end

    @modsettings_helper.save(builder, with_logging: true)
  end

  def update_mod_data(info_json_helper)
    uuid = info_json_helper.uuid
    name = info_json_helper.name

    if @mod_data_helper.has?(uuid)
      @mod_data_helper.set_installed(uuid)
    else
      @mod_data_helper.add_standard_entry(uuid, name)
    end

    @mod_data_helper.save(with_logging: true)
  end

  def make_modsettings_backup
    FileUtils.cd(@modsettings_helper.modsettings_dir) do
      return if File.exist?("modsettings.lsx.bak")

      FileUtils.cp("modsettings.lsx", "modsettings.lsx.bak")

      puts "Made backup of modsettings.lsx file."
    end
  end

  def copy_pak_files(mod_name)
    did_copy = false
    Dir.glob(File.join(Constants::DUMP_DIR, mod_name, "*.pak")).each do |pak_file|
      did_copy ||= self.safe_cp(
        pak_file,
        File.join(@config_helper.data["paths"]["appdata_dir"], "Mods"),
        with_logging: true
      )
    end

    return did_copy
  end

  def print_install_report(installed_mods)
    if installed_mods.size == 0
      puts "\nNothing to do."
    else
      standard_mods = installed_mods.select { |mod| mod[:type] == :standard }
      pak_only_mods = installed_mods.select { |mod| mod[:type] == :pak_only }

      puts "\n===== INSTALL REPORT ====="
      puts "You installed #{self.num_mods(standard_mods.size, "standard")}."
      puts standard_mods.map { |mod| "-> #{mod[:name]}" }
      if standard_mods.size >= 1
        puts "Nothing left to do for these."
      end
      puts ""
      puts "You installed #{self.num_mods(pak_only_mods.size, "pak-only")}."
      puts pak_only_mods.map { |mod| "-> #{mod[:name]}" }
      if pak_only_mods.size >= 1
        puts "These mods need to be activated in the in-game mod manager."
      end
    end
  end
end
