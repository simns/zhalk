require "zip"
require "nokogiri"

require_relative "base_cmd"
require_relative "helpers/info_json_helper"
require_relative "helpers/constants"

class InstallCmd < BaseCmd
  def help
    <<-HELP
Usage:
  zhalk install [options]

Description:
  This installs mods that are located in the mods/ directory. Each mod must be a .zip file. Mods \
that are already installed will be skipped.

Options:
  --dry-run     Don't install anything. Only list what would be installed.
  --update      Update all mods by reprocessing zip files in 'mods' folder. Same as 'update' command.

Aliases:
  in, i
HELP
  end

  def process_args(args)
    @is_update = args.include?("--update")

    if @is_update
      @logger.info("Running an update. All mods inside the 'mods' folder will be re-processed.")
      @logger.info("")
    end
  end

  def main(args)
    @logger.debug("===>> Starting: install")

    self.check_requirements!

    self.process_args(args)

    self.make_modsettings_backup

    installed_mods = []

    Dir.glob(File.join(Constants::MODS_DIR, "*.zip")).each do |zip_file_name|
      mod_name = /#{Constants::MODS_DIR}\/([\w\s\-\._'"]+)\.zip/.match(zip_file_name)[1]
      @logger.info("==== Processing #{mod_name} ====")

      if mod_name.nil?
        raise "Couldn't get mod name from zip file. Perhaps there are some unrecognized characters."
      end

      self.extract_mod_files(zip_file_name, mod_name)

      info_json_helper = InfoJsonHelper.new(mod_name)

      if info_json_helper.file_present?
        @logger.debug("Found an info.json file.")

        info_json_helper.load_data
        info_json_helper.check_fields!

        @logger.debug("info.json is valid.")

        mod_data_entry = @mod_data_helper.data[info_json_helper.uuid]
        if mod_data_entry && !@is_update
          if mod_data_entry["is_installed"]
            @logger.info("Mod is marked as installed. Skipping.")
            next
          else
            @logger.info("Mod is marked as inactive. Skipping.")
            next
          end
        end

        if !@is_update
          self.insert_into_modsettings(info_json_helper)
        end

        self.update_mod_data(info_json_helper)

        self.copy_pak_files(mod_name)

        installed_mods << {
          name: mod_name,
          type: :standard,
          is_inactive: @is_update && !@mod_data_helper.installed?(info_json_helper.uuid)
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
    if File.exist?(File.join(Constants::DUMP_DIR, mod_name)) && !@is_update
      @logger.info("Zip file already extracted. Skipping.")
      return
    end

    self.safe_mkdir(File.join(Constants::DUMP_DIR, mod_name))

    @logger.info("Extracting...")

    Zip::File.open(zip_file_name) do |zip_file|
      zip_file.each do |entry|
        filepath = File.join(Constants::DUMP_DIR, mod_name, entry.name)
        zip_file.extract(entry, filepath) { true }
      end
    end

    @logger.info("Successfully extracted zip file.")
  end

  def insert_into_modsettings(info_json_helper)
    @logger.debug("Starting #insert_into_modsettings")

    modsettings = @modsettings_helper.data

    if modsettings.at_css("attribute#UUID[value='#{info_json_helper.uuid}']")
      @logger.warn("Mod entry already exists in modsettings.lsx.")
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

    @modsettings_helper.save(builder, log_level: :info)
  end

  def update_mod_data(info_json_helper)
    uuid = info_json_helper.uuid
    name = info_json_helper.name

    if @is_update
      if @mod_data_helper.installed?(uuid)
        @mod_data_helper.set_updated(uuid)
        @mod_data_helper.save(with_logging: true)
      end

      return
    end

    if @mod_data_helper.has?(uuid)
      @mod_data_helper.set_installed(uuid)
    else
      @mod_data_helper.add_standard_entry(uuid, name)
    end

    @mod_data_helper.save(with_logging: true)
  end

  def make_modsettings_backup
    @logger.debug("Checking modsettings backup..")

    FileUtils.cd(@modsettings_helper.modsettings_dir) do
      if File.exist?("modsettings.lsx.bak")
        @logger.debug("modsettings.lsx.bak already exists.")
        return
      end

      FileUtils.cp("modsettings.lsx", "modsettings.lsx.bak")

      @logger.info("Made backup of modsettings.lsx file.")
    end
  end

  def copy_pak_files(mod_name)
    did_copy = false
    Dir.glob(File.join(Constants::DUMP_DIR, mod_name, "*.pak")).each do |pak_file|
      if @is_update
        FileUtils.cp(
          pak_file,
          File.join(@config_helper.data["paths"]["appdata_dir"], "Mods")
        )
        @logger.info("Copied file #{File.basename(pak_file)}.")

        did_copy = true
      else
        did_copy ||= self.safe_cp(
          pak_file,
          File.join(@config_helper.data["paths"]["appdata_dir"], "Mods"),
          log_level: :info
        )
      end
    end

    return did_copy
  end

  def print_install_report(installed_mods)
    @logger.info("")

    if installed_mods.size == 0
      @logger.info("Nothing to do.")
    else
      standard_mods = installed_mods.select { |mod| mod[:type] == :standard }
      pak_only_mods = installed_mods.select { |mod| mod[:type] == :pak_only }

      action_text = @is_update ? "updated files for" : "installed"

      @logger.info("===== INSTALL REPORT =====")
      @logger.info("You #{action_text} #{self.num_mods(standard_mods.size, "standard")}.")
      @logger.info(standard_mods.map { |mod| "-> #{mod[:name]} #{mod[:is_inactive] ? "(inactive)" : ""}" })
      if !@is_update && standard_mods.size >= 1
        @logger.info("Nothing left to do for these.")
      end
      @logger.info("")
      @logger.info("You #{action_text} #{self.num_mods(pak_only_mods.size, "pak-only")}.")
      @logger.info(pak_only_mods.map { |mod| "-> #{mod[:name]}" })
      if !@is_update && pak_only_mods.size >= 1
        @logger.info("These mods need to be activated in the in-game mod manager.")
      end
    end
  end
end
