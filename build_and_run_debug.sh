#!/bin/bash
set -e # Exit if a command fails (eg build)

./install.sh

# Enable debug logs
export G_MESSAGES_DEBUG=all
# Launch GTK Inspector upon app start:
export GTK_DEBUG=interactive

flatpak run com.github.childishgiant.mixer