require_relative "base_cmd"
require_relative "list_cmd"
require_relative "helpers/constants"

class ReorderCmd < BaseCmd
  def help
    <<-HELP
Usage:
  zhalk reorder

Description:
  This allows mods to be reordered so that dependencies of a mod can be set to load beforehand.
  Running the command will show the same table used in the 'list' command. From there, note \
the numbers of the mods you want to move. Input them as a comma-separated list. Then, choose \
a command in the next prompt, such as placing them at the beginning, end, or after a particular \
mod.

Options:
  This command does not have any options.
HELP
  end

  def main(args)
    self.check_requirements!

    table = ListCmd.new.construct_mod_table

    puts table
    puts "Select mods by typing a comma-separated list of numbers."

    mod_numbers = STDIN.gets.strip

    if !self.valid_mod_nums?(mod_numbers)
      puts "Invalid selection."
      return
    end

    mod_numbers = mod_numbers.split(",").map(&:to_i)

    mod_objs = @mod_data_helper.data.values
    selected_mod_names = mod_objs
      .select { |mod_obj| mod_numbers.include?(mod_obj["number"]) }
      .map { |mod_obj| mod_obj["mod_name"] }

    if selected_mod_names.empty?
      puts "No mods with those numbers."
      return
    end

    puts

    puts "You have selected:"
    puts selected_mod_names.map { |mod_name| "-> #{mod_name}" }

    puts

    puts <<~ACTIONS
           Choose one of these actions by typing the letter with any arguments:
            [b] Place at beginning
            [e] Place at end
            [a] Place after some [mod number]
            [c] Cancel
         ACTIONS

    command = STDIN.gets.strip

    existing_mod_objs = mod_objs.sort_by { |mod_obj| mod_obj["number"] }

    self.process_command(command, mod_numbers, existing_mod_objs)
  end

  def process_command(command, mod_numbers, mod_objs)
    command_parts = command.split(" ")

    mods_to_move = mod_objs.select { |mod_obj| mod_numbers.include?(mod_obj["number"]) }
    (0...mod_objs.size).reverse_each do |index|
      mod_obj = mod_objs[index]
      if mod_numbers.include?(mod_obj["number"])
        mod_objs.delete_at(index)
      end
    end

    case command_parts.first
    when "b"
      mod_objs.insert(0, *mods_to_move)
    when "e"
      mod_objs.insert(-1, *mods_to_move)
    when "a"
      if mod_numbers.include?(command_parts[1].to_i)
        puts "The mod you’re placing the others after cannot be part of the moving set. Please choose another."
        return
      end
      return if !self.put_after_mod(command_parts[1], mods_to_move, mod_objs)
    when "c"
      puts "Cancelling."
      return
    else
      puts "Unknown command."
      return
    end

    self.write_new_mod_data(mod_objs)

    self.write_new_modsettings

    puts "Finished reordering mods."
  end

  def put_after_mod(after_this_mod, mods_to_move, mod_objs)
    if self.num?(after_this_mod)
      after_this_mod = after_this_mod.to_i

      mod_index = mod_objs.find_index { |mod_obj| mod_obj["number"] == after_this_mod }

      if mod_index
        mod_objs.insert(mod_index + 1, *mods_to_move)
      else
        puts "Could not find the mod with number #{after_this_mod}."
        return false
      end
    else
      puts "Input after 'a' must be a single number corresponding to a mod."
      return false
    end

    return true
  end

  def write_new_mod_data(mod_objs)
    mod_objs.each_with_index do |mod_obj, index|
      @mod_data_helper.data[mod_obj["uuid"]]["number"] = index + 1
    end

    @mod_data_helper.save(with_logging: true)
  end

  def write_new_modsettings
    modsettings = @modsettings_helper.data

    parent_node = modsettings.at("node#Mods children")

    mod_entries = parent_node.css("node").sort_by do |node|
      uuid = node.at("attribute#UUID")["value"]

      next 0 if uuid == Constants::GUSTAV_DEV_UUID

      next @mod_data_helper.data.dig(uuid, "number") || 0
    end

    parent_node.children = Nokogiri::XML::NodeSet.new(modsettings, mod_entries)

    @modsettings_helper.save(with_logging: true)
  end

  def valid_mod_nums?(mod_numbers)
    return mod_numbers =~ /\A\d+\s*(,\s*\d+\s*)*\z/
  end
end
