require_relative "common"
require_relative "list"

def reorder_cmd
  check_requirements!

  mod_data = get_json_data("mod-data.json")

  table = construct_mod_table(mod_data)

  puts table
  puts "Select mods by typing a comma-separated list of numbers"

  mod_numbers = STDIN.gets.strip

  if !valid_mod_nums?(mod_numbers)
    puts "Invalid selection."
    return
  end

  mod_numbers = mod_numbers.split(",").map(&:to_i)

  selected_mod_names = mod_data.values
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

  process_command(command, mod_numbers, mod_data.values)
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
    return if !put_after_mod(command_parts[1], mods_to_move, mod_objs)
  when "c"
    puts "Cancelling."
    return
  else
    puts "Unknown command."
    return
  end

  puts "REUSLT"
  puts mod_objs.map { |d| d["mod_name"] }
end

def put_after_mod(after_this_mod, mods_to_move, mod_objs)
  if num?(after_this_mod)
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

def valid_mod_nums?(mod_numbers)
  return mod_numbers =~ /\A\d+\s*(,\s*\d+\s*)*\z/
end

def num?(num)
  return num.to_i.to_s == num.strip
end
