# frozen_string_literal: true

require_relative "base_cmd"
require_relative "helpers/constants"

class RefreshCmd < BaseCmd
  def help
    <<~HELP
      Usage:
        zhalk refresh

      Description:
        This reads mods in from the game's modsettings.lsx file, and checks if any mods were \
      disabled through the in-game mod manager. Run this command if you've made any changes in \
      the in-game mod manager, or you've installed mods through Zhalk that only consist of a \
      .pak file, and then enabled them in-game. Mods that are read from modsettings.lsx are saved \
      in this directory's mod-data.json file.

      Options:
        This command does not have any options.
    HELP
  end

  def main(_args)
    @logger.debug("===>> Starting: refresh")

    self.load_mods_from_modsettings

    self.update_disabled_mods

    self.update_enabled_mods
  end

  def load_mods_from_modsettings
    @logger.info("Reading from modsettings.lsx...")

    starting_number = (@mod_data_helper.data.values.map { |mod| mod["number"] }.max || 0) + 1
    @logger.debug("Next mod number would be #{starting_number}.")

    num_added = 0

    modsettings = @modsettings_helper.data
    modsettings.css("node#Mods node#ModuleShortDesc").each do |node|
      uuid = node.at("attribute#UUID")["value"]
      name = node.at("attribute#Name")["value"]

      if uuid.nil?
        raise "Did not find a UUID for mod #{name}"
      end

      @logger.debug("Found node: uuid: #{uuid}, name: \"#{name}\".")

      if uuid == Constants::GUSTAV_DEV_UUID
        @logger.debug("Not importing the Gustav entry.")
        next
      end

      if !@mod_data_helper.has?(uuid)
        @mod_data_helper.add_modsettings_entry(uuid, name, starting_number + num_added)

        num_added += 1

        @logger.debug("==> mod-data.json does not have this entry, so I'm adding it.")
      else
        @logger.debug("mod-data.json already has this entry, so I'm skipping.")
      end
    end

    if num_added >= 1
      @mod_data_helper.save

      @logger.info("Saved #{self.num_mods(num_added, "new")} in mod-data.json.")
    else
      @logger.info("No new entries.")
    end
  end

  def update_disabled_mods
    num_updated = 0

    @logger.info("")
    @logger.info("Checking for mods that were disabled in-game...")

    @mod_data_helper.data.each_key do |uuid|
      next if @modsettings_helper.has?(uuid) ||
              !@mod_data_helper.installed?(uuid)

      @mod_data_helper.set_installed(uuid, is_installed: false)

      num_updated += 1
    end

    if num_updated >= 1
      @mod_data_helper.save

      @logger.info("Updated #{self.num_mods(num_updated, "disabled")}.")
    else
      @logger.info("No mods were updated.")
    end
  end

  def update_enabled_mods
    num_updated = 0

    @logger.info("")
    @logger.info("Checking for mods that were enabled in-game...")

    @mod_data_helper.data.each_key do |uuid|
      next if !@modsettings_helper.has?(uuid) ||
              @mod_data_helper.installed?(uuid)

      @mod_data_helper.set_installed(uuid)

      num_updated += 1
    end

    if num_updated >= 1
      @mod_data_helper.save

      @logger.info("Updated #{self.num_mods(num_updated, "enabled")}.")
    else
      @logger.info("No mods were updated.")
    end
  end
end
