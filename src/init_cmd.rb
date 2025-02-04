require_relative "base_cmd"
require_relative "helpers/constants"

class InitCmd < BaseCmd
  def help
    <<-HELP
Usage:
  zhalk init

Description:
  Runs a series of commands to initialize the Zhalk tool:
    - Creates the 'mods' directory in this folder. This is where you will place your mods as .zip files.
    - Creates the 'dump' direcotry in this folder. This is a folder the tool uses to store the extracted files from the .zip files.
    - Creates a 'conf.toml' config file from the template.
    - Creates a 'mod-data.json' file. This file stores all the necessary info about your mods.

Options:
  This command does not have any options.
HELP
  end

  def main(args)
    self.safe_mkdir(Constants::MODS_DIR, with_logging: true)
    self.safe_mkdir(Constants::DUMP_DIR, with_logging: true)

    self.safe_cp("conf.toml.template", "conf.toml", with_logging: true)

    self.safe_create("mod-data.json", content: "{}", with_logging: true)

    puts "Done."
  end
end
