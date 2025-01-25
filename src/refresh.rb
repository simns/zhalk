require_relative "common"

GUSTAV_DEV_UUID = "28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"

def refresh_cmd
  puts "Reading from modsettings.lsx..."

  mod_data = get_json_data("mod-data.json")
  starting_number = (mod_data.values.map { |mod| mod["number"] }.max || 0) + 1
  num_added = 0

  modsettings = get_modsettings
  modsettings.css("node#Mods node#ModuleShortDesc").each do |node|
    uuid = node.at("attribute#UUID")["value"]
    name = node.at("attribute#Name")["value"]

    if uuid.nil?
      raise "Did not find a UUID for mod #{name}"
    end

    next if uuid == GUSTAV_DEV_UUID

    if mod_data[uuid].nil?
      mod_data[uuid] = {
        "is_installed" => true,
        "mod_name" => name,
        "uuid" => uuid,
        "number" => starting_number + num_added,
        "created_at" => Time.now.to_s,
        "updated_at" => Time.now.to_s,
      }

      num_added += 1
    end
  end

  if num_added >= 1
    save_json_data("mod-data.json", mod_data)

    puts "Saved #{num_mods(num_added, "new")} in mod-data.json."
  else
    puts "No new entries."
  end
end
