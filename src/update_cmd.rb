require_relative "base_cmd"
require_relative "install_cmd"

class UpdateCmd < BaseCmd
  def help
    <<-HELP
Usage:
  zhalk update

Description:
  This command updates all the mods in the 'mods' directory. It will re-extract all the .zip files \
and copy .pak files into the game's mod folder where existing files will be overwritten. This \
applies to disabled mods too, but they will not be activated upon running this command.

Options:
  This command does not have any options.

Aliases:
  up
HELP
  end

  def main(args)
    self.check_requirements!

    InstallCmd.new.run("--update", *args)
  end
end
