require_relative "base_cmd"
require_relative "helpers/constants"

class RefreshCmd < BaseCmd
  def run
    self.check_requirements!

    puts "Reading from modsettings.lsx..."

    starting_number = (@mod_data_helper.data.values.map { |mod| mod["number"] }.max || 0) + 1
    num_added = 0

    modsettings = @modsettings_helper.data
    modsettings.css("node#Mods node#ModuleShortDesc").each do |node|
      uuid = node.at("attribute#UUID")["value"]
      name = node.at("attribute#Name")["value"]

      if uuid.nil?
        raise "Did not find a UUID for mod #{name}"
      end

      next if uuid == Constants::GUSTAV_DEV_UUID

      if !@mod_data_helper.has?(uuid)
        @mod_data_helper.add_modsettings_entry(uuid, name, starting_number + num_added)

        num_added += 1
      end
    end

    if num_added >= 1
      @mod_data_helper.save

      puts "Saved #{self.num_mods(num_added, "new")} in mod-data.json."
    else
      puts "No new entries."
    end
  end
end
