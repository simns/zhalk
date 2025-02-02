require "json"
require "terminal-table"
require "date"

require_relative "common"

MOD_TYPE_MAP = {
  "standard" => "Standard",
  "from_modsettings" => "From modsettings"
}

def list_cmd
  check_requirements!

  mod_data = get_json_data("mod-data.json")

  if mod_data.keys.size == 0
    puts "No mods installed yet."
    return
  end

  table = construct_mod_table(mod_data)

  puts table
end

def construct_mod_table(mod_data)
  mod_entries = mod_data.values.sort_by { |mod_entry| mod_entry["number"] }
  mod_entry_rows = mod_entries.map do |entry|
    [
      entry["number"],
      entry["is_installed"] ? "yes" : "no",
      entry["mod_name"],
      MOD_TYPE_MAP[entry["type"]],
      Time.parse(entry["updated_at"]).strftime("%a %b %d, %Y %T")
    ]
  end

  table = Terminal::Table.new do |t|
    t.headings = ["#", "Active?", "Name", "Type", "Last installed"]
    t.rows = mod_entry_rows
    t.style = {
      border_left: false,
      border_right: false,
      border_x: "-",
      border_i: "|"
    }
  end

  return table
end
