# frozen_string_literal: true

require_relative "base_cmd"
require_relative "helpers/constants"

class RefreshCmd < BaseCmd
  def help
    <<~HELP
      Usage:
        zhalk refresh

      Description:
        This reads mods in from the game's modsettings.lsx file. Run this command if you have mods \
      installed with the in-game mod manager, or after you've installed mods with this tool that only \
      consist of a .pak file and thus need to be activated in-game. Mods that are read from \
      modsettings.lsx are saved in this directory's mod-data.json file.

      Options:
        This command does not have any options.
    HELP
  end

  def main(_args)
    @logger.debug("===>> Starting: refresh")

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
end
