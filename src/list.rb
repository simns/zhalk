require "json"
require "terminal-table"

require_relative "common"

def list_cmd
  mod_data = get_json_data("mod-data.json")

  mod_entries = mod_data.values.sort_by { |mod_entry| mod_entry["number"] }
  mod_entry_rows = mod_entries.map do |entry|
    [
      entry["number"],
      entry["mod_name"],
      "March 39th 2003"
    ]
  end

  table = Terminal::Table.new do |t|
    t.headings = ["#", "Name", "Installed at"]
    t.rows = mod_entry_rows
    t.style = {
      border_left: false,
      border_right: false,
      border_x: "-",
      border_i: "|"
    }
  end

  puts table
end
