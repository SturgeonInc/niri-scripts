#!/usr/bin/env sh

APPIMAGE_HOME="$HOME/.AppImages"

eval "$(find "$APPIMAGE_HOME" -maxdepth 1 -name 'linux-hayase-*.AppImage' | head -n 1)"
