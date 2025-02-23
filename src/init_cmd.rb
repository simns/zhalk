# frozen_string_literal: true

require_relative "base_cmd"
require_relative "helpers/constants"

class InitCmd < BaseCmd
  def help
    <<~HELP
      Usage:
        zhalk init

      Description:
        Runs a series of commands to initialize the Zhalk tool:
          - Creates the 'mods' directory in the project folder. This is where you will place your mods as .zip files.
          - Creates the 'dump' direcotry in the project folder. This is a folder the tool uses to store the extracted files from the .zip files.
          - Creates the 'inactive' directory in the project folder. This is where inactive mods are stored.
          - Creates a 'conf.toml' config file from the template.
          - Creates a 'mod-data.json' file. This file stores all the necessary info about your mods.

      Options:
        This command does not have any options.
    HELP
  end

  def main(_args)
    @logger.debug("===>> Starting: init")

    self.safe_mkdir(Filepaths.root(Constants::MODS_DIR), log_level: :info)
    self.safe_mkdir(Filepaths.root(Constants::DUMP_DIR), log_level: :info)
    self.safe_mkdir(Filepaths.root(Constants::INACTIVE_DIR), log_level: :info)

    self.safe_cp(
      Filepaths.root("conf.toml.template"),
      Filepaths.root("conf.toml"),
      log_level: :info
    )

    self.safe_create(Filepaths.root("mod-data.json"), content: "{}", log_level: :info)

    @logger.info("Done.")
  end
end
