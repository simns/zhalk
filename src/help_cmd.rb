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
        refresh         Load in mods from the game's 'modsettings.lsx' file.
        reorder         Reorder installed mods.
        activate        Activate a mod that has been deactivated.
        deactivate      Deactivate a mod so that it is not loaded into the game.

      Options:

        Global:
          --help        Show help for a specific command.

        install:
          --dry-run     Simulate installation without making changes.

        list:
          --all         Show all mods (default).
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
