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
HELP
  end

  def main(args)
    self.check_requirements!

    if args[0].nil? || !self.num?(args[0])
      puts "Invalid arg. Please pass a number corresponding to the mod."
      return
    end

    target_mod_number = args[0].to_i
    target_mod = @mod_data_helper.data.values.detect { |mod_obj| mod_obj["number"] == target_mod_number }

    if target_mod.nil?
      puts "Could not find a mod with number: #{target_mod_number}."
      return
    elsif target_mod["is_installed"]
      puts "Target mod is already active."
      return
    end

    puts "Reactivating mod:"
    puts "-> #{target_mod["mod_name"]}"

    target_uuid = target_mod["uuid"]

    self.load_inactive_into_modsettings(target_uuid)

    self.delete_inactive_backup(target_uuid)

    self.update_mod_data(target_uuid)

    puts "Done."
  end

  def load_inactive_into_modsettings(target_uuid)
    inactive_entry = @base_helper.get_xml_data(File.join(Constants::INACTIVE_DIR, "#{target_uuid}.xml"))

    mods = @modsettings_helper.data.css("node#Mods node")
    mods << inactive_entry.at_css("node#ModuleShortDesc")

    mods = mods.sort_by do |node|
      uuid = node.at("attribute#UUID")["value"]

      next 0 if uuid == Constants::GUSTAV_DEV_UUID

      next @mod_data_helper.data.dig(uuid, "number") || 0
    end

    @modsettings_helper.data.at_css("node#Mods children").children = Nokogiri::XML::NodeSet.new(
      @modsettings_helper.data,
      mods
    )

    @modsettings_helper.save(with_logging: true)
  end

  def update_mod_data(target_uuid)
    @mod_data_helper.set_installed(target_uuid)

    @mod_data_helper.save(with_logging: true)
  end

  def delete_inactive_backup(target_uuid)
    # TODO: Implement
  end
end
