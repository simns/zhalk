require "terminal-table"
require "date"

require_relative "base_cmd"

class ListCmd < BaseCmd
  MOD_TYPE_MAP = {
    "standard" => "Standard",
    "from_modsettings" => "From modsettings"
  }

  def help
    <<-HELP
Usage:
  zhalk list [options]

Description:
  This lists mods in a table. By default, the table shows active and inactive mods.

Options:
  --active      Show only active mods
  --inactive    Show only inactive mods

Aliases:
  ls, l
HELP
  end

  def main(args)
    self.check_requirements!

    if @mod_data_helper.data.keys.size == 0
      puts "No mods installed yet."
      return
    end

    puts construct_mod_table
  end

  def construct_mod_table
    mod_data = @mod_data_helper.data

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
end
