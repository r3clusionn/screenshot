#!/bin/sh
# Build and install the three screenshot tools from their repos:
#   xregion (select a region or window), grab (capture it as PNG), xclip (put it on the clipboard).
# Usage: sh install.sh [PREFIX]    default ~/.local; doas sh install.sh /usr/local for everyone
# Needs git, make, a C compiler, libX11 and zlib (headers included).
set -eu
PREFIX=${1:-$HOME/.local}
src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
git clone -q --depth 1 https://github.com/r3clusionn/xregion "$src/xregion"
git clone -q --depth 1 https://github.com/r3clusionn/scripts "$src/scripts"
mkdir -p "$PREFIX/bin"
make -s -C "$src/xregion" install PREFIX="$PREFIX"
cc -O2 -o "$PREFIX/bin/grab" "$src/scripts/bin/grab.c" -lX11 -lz
cc -O2 -o "$PREFIX/bin/xclip" "$src/scripts/bin/xclip.c" -lX11
echo "xregion, grab and xclip installed in $PREFIX/bin"
