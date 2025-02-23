# Zhalk

Zhalk is a command-line mod manager for _Baldur's Gate 3_ aimed to work on any Linux
distro.

It is made with the intention of being simple and requiring few dependencies.

## Dependencies

Zhalk requires Ruby.

Linux distros often come with Ruby pre-installed but if it is not installed,
install it with a tool such as:

- [rbenv](https://rbenv.org/)
- [rvm](https://rvm.io/)
- [asdf](https://asdf-vm.com/)

The version I used for this project is in the `.tool-versions` and `.ruby-version` files.

## Setup

1. Clone this repo.

   ```
   git clone git@github.com:simns/zhalk.git
   ```

1. cd into the repo.

   ```
   cd zhalk
   ```

1. Install the `bundler` gem.

   ```
   gem install bundler
   ```

1. Use bundler to install the required gems.

   ```
   bundle install
   ```

## Get started

1. Zhalk uses a few files and folders to manage the mods. Initialize them with this command:

   ```sh
   ./zhalk init
   ```

1. Edit the configuration file: `conf.toml` and input your Baldur's Gate 3 AppData directory.

1. Next, move your mods as `.zip` files into the newly created `mods` folder. Then, install the mods with:

   ```sh
   ./zhalk install
   ```

   If you have existing mods in the game's `modsettings.lsx` file, read them in with:

   ```sh
   ./zhalk refresh
   ```

   To see all the mods you have installed, run:

   ```sh
   ./zhalk list
   ```

That's the basic usage!

### Further docs

If you want more info on the rest of the commands, see [this doc](/docs/usage.md).

You can also run `./zhalk --help` to see how to use the tool.

### FAQ

See [this FAQ doc](/docs/faq.md).

### Coffee

If you like this tool, consider buying me a coffee ☕.
Otherwise, happy gaming!

<a href="https://www.buymeacoffee.com/simns" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-green.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
