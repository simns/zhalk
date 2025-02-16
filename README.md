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

Clone this repo.

```
git clone git@github.com:simns/zhalk.git
```

cd into the repo.

```
cd zhalk
```

Install the `bundler` gem.

```
gem install bundler
```

Use bundler to install the required gems.

```
bundle install
```

## Get started

Zhalk uses a few files and folders to manage the mods. Initialize them with this command:

```sh
./zhalk init
```

Edit the configuration file: `conf.toml` with your Baldur's Gate 3 AppData directory.

Next, move your mods as `.zip` files into this project's `mods` folder. Then install them with:

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

Alternatively, you can run `./zhalk --help` to get help.

### FAQ

See [this FAQ doc](/docs/faq.md).
