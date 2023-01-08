# Mixer
[![All Contributors](https://img.shields.io/github/all-contributors/childishgiant/mixer)](#contributors-)
### Change the volume of apps

A no-frills volume mixer, with simplicity and usability at its core.

* Simple volume controls including balance and output selection
* Individually change each audio source's values

<p align="center">
<img width="250" src="data/icons/com.github.childishgiant.mixer.svg" alt="Logo">
<br>
<img width="400" src="docs/light.png" alt="Light mode">
<img width="400" src="docs/dark.png" alt="Dark mode">
</p>

# Installing

<a href="https://appcenter.elementary.io/com.github.childishgiant.mixer"><img src="https://appcenter.elementary.io/badge.svg" height="75" /></a>
<a href="https://flathub.org/apps/details/com.github.childishgiant.mixer"><img src="https://flathub.org/assets/badges/flathub-badge-en.svg" height="75" /></a>

Releases are also always available as flatpaks on the [releases page](https://github.com/childishgiant/mixer/releases).

## Nightly builds

Nightly builds are handled by GitHub actions and the latest one can be found on [nightly.link](https://nightly.link/ChildishGiant/mixer/workflows/ci/main/Mixer.zip)
## Install it from source

You can of course download and install this app from source.

### Dependencies

Ensure you have these dependencies installed

* glib-2.0
* gee-0.8
* gtk4
* granite-7
* libpulse
* libpulse-mainloop-glib

### Install, build and run

```bash
# Install requirements on ubuntu-based distros
sudo apt install meson ninja-build libpulse-dev valac libgtk-4-dev libgee-0.8-dev libgranite-7-dev
# Or on fedora
sudo dnf install libadwaita-devel libgee-devel pulseaudio-libs-devel

# Install flatpak runtime and sdk
flatpak remote-add --if-not-exists --system appcenter https://flatpak.elementary.io/repo.flatpakrepo
flatpak install -y appcenter io.elementary.Platform io.elementary.Sdk

# clone repository
git clone https://github.com/ChildishGiant/mixer mixer
# cd to dir
cd mixer

# Build and install
./install.sh

# Uncomment to enable debug logs
# export G_MESSAGES_DEBUG=all
# Uncomment to launch GTK Inspector upon app start:
# export GTK_DEBUG=interactive

# Run
flatpak run com.github.childishgiant.mixer
```

### Generating translation files

```bash
# after setting up meson build
cd build

# generates pot file
ninja com.github.childishgiant.mixer-pot
ninja extra-pot

# to regenerate and propagate changes to every po file
ninja com.github.childishgiant.mixer-update-po
ninja extra-update-po
```

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/ChildishGiant"><img src="https://avatars.githubusercontent.com/u/13716824?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Allie</b></sub></a><br /><a href="#design-ChildishGiant" title="Design">🎨</a> <a href="https://github.com/ChildishGiant/mixer/commits?author=ChildishGiant" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/SubhadeepJasu"><img src="https://avatars.githubusercontent.com/u/20795161?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Subhadeep Jasu</b></sub></a><br /><a href="https://github.com/ChildishGiant/mixer/commits?author=SubhadeepJasu" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/JeysonFlores"><img src="https://avatars.githubusercontent.com/u/68255757?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jeyson Flores</b></sub></a><br /><a href="#translation-JeysonFlores" title="Translation">🌍</a></td>
    <td align="center"><a href="https://dribbble.com/Suzie97"><img src="https://avatars.githubusercontent.com/u/68198116?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Rajdeep Singha</b></sub></a><br /><a href="https://github.com/ChildishGiant/mixer/commits?author=Suzie97" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/asdffdsdaf"><img src="https://avatars.githubusercontent.com/u/87440869?v=4?s=100" width="100px;" alt=""/><br /><sub><b>asdf</b></sub></a><br /><a href="#translation-asdffdsdaf" title="Translation">🌍</a></td>
    <td align="center"><a href="https://nathanbonnemains.squill.fr"><img src="https://avatars.githubusercontent.com/u/45366162?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Nathan Bonnemains</b></sub></a><br /><a href="#translation-NathanBnm" title="Translation">🌍</a></td>
    <td align="center"><a href="http://www.yakusha.net"><img src="https://avatars.githubusercontent.com/u/6218679?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Sabri Ünal</b></sub></a><br /><a href="#translation-libreajans" title="Translation">🌍</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/rene-coty"><img src="https://avatars.githubusercontent.com/u/95506494?v=4?s=100" width="100px;" alt=""/><br /><sub><b>rene-coty</b></sub></a><br /><a href="#translation-rene-coty" title="Translation">🌍</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
