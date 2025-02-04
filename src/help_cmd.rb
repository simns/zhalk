class HelpCmd
  def run
    puts <<-HELP
zhalk - A command-line mod manager for Baldur's Gate 3

Usage:
  zhalk <command> [options]

Commands:
  init       Initialize the environment with necessary files and folders.
  install    Install mods (.zip) from the 'mods' directory here.
  list       List installed mods.
  refresh    Load in mods from the game's 'modsettings.lsx' file.
  reorder    Reorder installed mods.

Options:

  Global:
    --help          Show help for a specific command.

  install:
    --dry-run       Simulate installation without making changes.

  list:
    --all           Show all mods (default).
    --active        Show only active mods.
    --inactive      Show only inactive mods.

For more details on a command, run:
  zhalk <command> --help
HELP
  end
end
