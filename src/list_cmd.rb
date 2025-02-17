# frozen_string_literal: true

require "terminal-table"
require "date"

require_relative "base_cmd"

class ListCmd < BaseCmd
  MOD_TYPE_MAP = {
    "standard" => "Standard",
    "from_modsettings" => "From modsettings"
  }.freeze

  def help
    <<~HELP
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

  def process_args(args)
    @logger.debug("Received args: #{args}")

    if args.include?("--active") && args.include?("--inactive")
      raise ArgumentError, "Cannot pass both --active and --inactive options."
    end

    @active_only = args.include?("--active")
    @inactive_only = args.include?("--inactive")

    @logger.debug("@active_only is #{@active_only}")
    @logger.debug("@inactive_only is #{@inactive_only}")
  end

  def main(args)
    @logger.debug("===>> Starting: list")

    self.check_requirements!

    self.process_args(args)

    if @mod_data_helper.data.keys.empty?
      @logger.info("No mods installed yet.")
      return
    end

    puts construct_mod_table
  end

  def construct_mod_table
    mod_data = @mod_data_helper.data

    mod_entries = mod_data.values.sort_by { |mod_entry| mod_entry["number"] }

    if @active_only
      mod_entries = mod_entries.select { |mod_entry| mod_entry["is_installed"] }
    elsif @inactive_only
      mod_entries = mod_entries.reject { |mod_entry| mod_entry["is_installed"] }
    end

    mod_entry_rows = mod_entries.map do |entry|
      [
        entry["number"],
        entry["is_installed"] ? "yes" : "no",
        entry["mod_name"],
        MOD_TYPE_MAP[entry["type"]],
        Time.parse(entry["updated_at"]).strftime("%a %b %d, %Y %T")
      ]
    end

    @logger.debug("There are #{num_mods(mod_entry_rows.size)} installed.")

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
