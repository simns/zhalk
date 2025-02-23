# frozen_string_literal: true

class HelpCmd
  def run
    puts <<~HELP
      zhalk - A command-line mod manager for Baldur's Gate 3

      Usage:
        zhalk <command> [options]

      Commands:

        init            Initialize the environment with necessary files and folders.
        install         Install mods (.zip) from the 'mods' directory here.
        list            List installed mods.
        refresh         Sync up mods with the modsettings.lsx file.
        reorder         Reorder installed mods.
        activate        Activate a mod that has been deactivated.
        deactivate      Deactivate a mod so that it is not loaded into the game.

      Options:

        Global:
          --help        Show help for a specific command.

        install:
          --update      Update all mods by reprocessing zip files in 'mods' folder. Same as 'update' command.

        list:
          --active      Show only active mods.
          --inactive    Show only inactive mods.

      Aliases:

        install         in, i
        list            ls, l
        activate        enable
        deactivate      disable


      For more details on a command, run:
        zhalk <command> --help
    HELP
  end
end
