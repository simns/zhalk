require_relative "base_cmd"
require_relative "helpers/constants"

class DeactivateCmd < BaseCmd
  def help
    <<-HELP
Usage:
  zhalk deactivate [MOD_NUMBER]

Description:
  This sets a mod as inactive, which removes its entry from the game's modsettings.lsx file. This will \
not delete the mod files. Specify the mod with the associated mod number. You can see the numbers \
with the 'list' command.
  Mod can be easily reactivated with the 'activate' command.

Options:
  This command does not have any options.

Aliases:
  disable
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
    elsif !target_mod["is_installed"]
      puts "Target mod is already deactivated."
      return
    end

    puts "Deactivating mod:"
    puts "-> #{target_mod["mod_name"]}"

    target_uuid = target_mod["uuid"]

    self.create_xml_backup(target_uuid)

    self.remove_from_modsettings(target_uuid)

    self.update_mod_data(target_uuid)

    puts "Done."
  end

  def create_xml_backup(target_uuid)
    uuid_attribute = @modsettings_helper.data.at_css("attribute#UUID[value='#{target_uuid}']")
    if uuid_attribute.nil?
      raise "Could not find mod entry in modsettings.lsx. Cannot proceed."
    end

    mod_entry = uuid_attribute.parent

    File.write(
      File.join(Constants::INACTIVE_DIR, "#{target_uuid}.xml"),
      mod_entry.to_xml
    )
  end

  def remove_from_modsettings(target_uuid)
    @modsettings_helper.data.at_css("attribute#UUID[value='#{target_uuid}']").parent.remove

    @modsettings_helper.save(with_logging: true)
  end

  def update_mod_data(target_uuid)
    @mod_data_helper.set_installed(target_uuid, false)

    @mod_data_helper.save(with_logging: true)
  end
end
