#!/usr/bin/env sh

: "${APPIMAGE_HOME:=$HOME/.AppImages}"

eval "$(find "$APPIMAGE_HOME" -maxdepth 1 -name 'Vesktop-*.AppImage' | head -n 1)"
