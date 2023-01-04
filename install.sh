#!/bin/bash
set -e

flatpak-builder build com.github.childishgiant.mixer.yml --user --install --force-clean

