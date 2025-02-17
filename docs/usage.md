# Usage manual

## Commands

### Install

```
Usage:
  zhalk install
```

This command reads each `.zip` file in the `mods` directory. The first step is extracting. Extracted files are placed in the `dump` directory inside a folder corresponding to the zip file's name.

There are two types of mods that this tool supports. One is a mod that includes an `info.json` file, along with the `.pak` files.
This contains some metadata about the mod and is used when writing the entry into the game's `modsettings.lsx` file.
The other type is one that only contains the `.pak` files.
Currently, Zhalk does not know how to read the binary in `.pak` files so all it does it move those files into the game's `Mods` folder inside `AppData`.
After those files are moved, they need to be activated in the In-game Mod Manager.

Zhalk keeps track of what is installed with its own **`mod-data.json`** file.
When reading through each zip file in the `mods` folder, if a mod already has an entry in that json file, it will be skipped.
Moreover, if the `is_installed` property for a given mod is set to `true`, it does not need to be reinstalled.
If it is `false`, it means it is deactivated, so it should not be modified.

### Update

```
Usage:
  zhalk update
```

You might use this command when you have downloaded new versions of any mods and placed the new zip files into the `mods` folder.

This command is similar to the `install` command in that it goes through the same process, but it does not skip mods even if their entry exists in `mod-data.json`.

It reads each zip file in the `mods` directory and re-extracts them.
Then it goes through and copies the `.pak` files into the game's `Mods` folder
and lets them get overwritten.

Currently there is no support for updating individual mods.

### Refresh

```
Usage:
  zhalk refresh
```

This command is used to read mods installed with the In-game Mod Manager.
These mods appear in the game's `modsettings.lsx` file.
Using this command will read that file and add entries to the `mod-data.json` file.

If the entry already exists in `mod-data.json`, it is skipped.

### Reorder

```
Usage:
  zhalk reorder
```

This is an important command that reorders mod entries in `modsettings.lsx`.
Reordering should be used to ensure that any mod's dependencies come before it.

Note that the order shown in the `list` command doesn't always reflect the order in the `modsettings.lsx` file.
This can happen in the following scenario:

1. You install a mod "Mod A," which puts it at the end of the `modsettings.lsx` file.
1. Then you read in existing mods with the `refresh` command.
1. That reads the mods _before_ Mod A in `modsettings.lsx`, and places them _after_ Mod A in `mod-data.json`.

Therefore, when installing/reading in mods for the first time, take care to run the `reorder` command for each set of mod dependencies.

The reorder command does not accept any options because it starts an interactive UI where you select the mods that need to move.
Then, you select an action for those, such as placing them at the beginning of the list, at the end, or after a particular mod.
You can do this for deactivated mods too.
Whenever those mods are activated again, they will be placed in their proper order.

### Activate / Deactivate

```
Usage:
  zhalk activate

  zhalk deactivate
```

Deactivating or disabling a mod makes it not load into the game.
Conversely, activating or enabling a mod restores it into the game.
Mostly, this involves removing or inserting the mod's entry into the `modsettings.lsx` file.

What this doesn't do is delete the `.pak` files or the `.zip` files in the tool's `mods` folder.

Note, there is no command to "uninstall" or delete mods.
This is because the `.pak` files can safely sit in the game's folders and not affect anything as long as the `modsettings.lsx` file is updated correctly.
