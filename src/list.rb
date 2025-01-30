require "json"
require "terminal-table"
require "date"

require_relative "common"

def list_cmd
  check_requirements!

  mod_data = get_json_data("mod-data.json")

  table = construct_mod_table(mod_data)

  puts table
end

def construct_mod_table(mod_data)
  mod_entries = mod_data.values.sort_by { |mod_entry| mod_entry["number"] }
  mod_entry_rows = mod_entries.map do |entry|
    [
      entry["number"],
      entry["mod_name"],
      Time.parse(entry["created_at"]).strftime("%a %b %d, %Y %T"),
      Time.parse(entry["updated_at"]).strftime("%a %b %d, %Y %T")
    ]
  end

  table = Terminal::Table.new do |t|
    t.headings = ["#", "Name", "Installed at", "Updated at"]
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
