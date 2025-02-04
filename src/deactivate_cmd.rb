require_relative "base_cmd"

class DeactivateCmd < BaseCmd
  def help
    <<-HELP
Usage:
  zhalk deactivate [MOD_NUMBER]

Description:
  This sets a mod as inactive, which removes it from the game's modsettings.lsx file. This will \
not delete the mod files. Specify the mod with the associated mod number. You can see this \
with the 'list' command.
  Mod can be easily reactivated with the 'activate' command.

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
    end

    puts "Deactivating mod:"
    puts "-> #{target_mod["mod_name"]}"

    target_uuid = target_mod["uuid"]

    File.write(
      File.join(Constants::INACTIVE_DIR, "#{target_uuid}.xml"),
      @modsettings_helper.data.at_css("attribute#UUID[value='#{target_uuid}']").parent.to_xml
    )

    puts
    puts "Done."
  end
end
