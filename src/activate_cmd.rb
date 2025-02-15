require "nokogiri"

require_relative "base_cmd"
require_relative "helpers/base_helper"
require_relative "helpers/constants"

class ActivateCmd < BaseCmd
  def initialize
    super

    @base_helper = BaseHelper.new
  end

  def help
    <<-HELP
Usage:
  zhalk activate [MOD_NUMBER]

Description:
  This sets a deactivated mod back to active. It adds the mod entry back into modsettings.lsx. \
Specify the mod with the associated mod number. You can see the numbers with the 'list' command.

Options:
  This command does not have any options.

Aliases:
  enable
HELP
  end

  def main(args)
    @logger.debug("===>> Starting: activate")

    self.check_requirements!

    if args[0].nil? || !self.num?(args[0])
      @logger.error("Invalid arg. Please pass a number corresponding to the mod.")
      return
    end

    target_mod_number = args[0].to_i
    target_mod = @mod_data_helper.data.values.detect { |mod_obj| mod_obj["number"] == target_mod_number }

    if target_mod.nil?
      @logger.error("Could not find a mod with number: #{target_mod_number}.")
      return
    elsif target_mod["is_installed"]
      @logger.info("Target mod is already active.")
      return
    end

    @logger.info("Reactivating mod:")
    @logger.info("-> #{target_mod["mod_name"]}")

    target_uuid = target_mod["uuid"]

    self.load_inactive_into_modsettings(target_uuid)

    self.update_mod_data(target_uuid)

    self.delete_inactive_backup(target_uuid)

    @logger.info("Done.")
  end

  def load_inactive_into_modsettings(target_uuid)
    inactive_mod_filepath = File.join(Constants::INACTIVE_DIR, "#{target_uuid}.xml")
    if !File.exist?(inactive_mod_filepath)
      raise "Could not find inactive mod's backup xml file."
    end

    inactive_mod_doc = @base_helper.get_xml_data(inactive_mod_filepath)
    inactive_entry = inactive_mod_doc.at_css("node#ModuleShortDesc")

    @logger.debug("Loaded in #{target_uuid}.xml:")
    @logger.debug(inactive_mod_doc.to_xml)

    if inactive_entry.nil?
      raise "Could not find inactive mod entry in the backup file."
    end

    mods = @modsettings_helper.data.css("node#Mods node")
    mods << inactive_entry

    mods = mods.sort_by do |node|
      uuid = node.at("attribute#UUID")["value"]

      next 0 if uuid == Constants::GUSTAV_DEV_UUID

      next @mod_data_helper.data.dig(uuid, "number") || 0
    end

    @modsettings_helper.data.at_css("node#Mods children").children = Nokogiri::XML::NodeSet.new(
      @modsettings_helper.data,
      mods
    )

    @modsettings_helper.save(log_level: :info)
  end

  def update_mod_data(target_uuid)
    @logger.debug("Setting is_installed to true.")

    @mod_data_helper.set_installed(target_uuid)

    @mod_data_helper.save(log_level: :info)
  end

  def delete_inactive_backup(target_uuid)
    # TODO: Implement
    @logger.info("Backup file will not be deleted for now. Feel free to delete it manually.")
  end
end
