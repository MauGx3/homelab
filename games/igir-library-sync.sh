#!/bin/sh
# @param {...string} $@ Input directories to merge into this collection
set -eu

# Save current working directory and restore on exit (POSIX-friendly)
ORIG_PWD=$(pwd)
trap 'cd "$ORIG_PWD"' EXIT
cd "$(dirname "$0")"

# Helper: shell-quote a string for safe eval usage (single-quote, escape existing single quotes)
quote() {
  # Uses sed to escape single quotes in the input
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\''/g")"
}

# Build input arguments: transform each positional argument into: --input 'ARG'
INPUT_ARGS=
for INPUT in "$@"; do
  INPUT_ARGS="$INPUT_ARGS --input $(quote "$INPUT")"
done

# Cartridge-based consoles, 1st-5th generations
# Trust checksums in archive headers, don't checksum archives (we only care about the contents)
eval "npx --yes igir@latest move zip test clean report \
  --dat './No-Intro*.zip' \
  --dat-name-regex-exclude '/encrypted|source code/i' \
  --input './No-Intro/' \
  $INPUT_ARGS \
  --input-checksum-max CRC32 \
  --input-checksum-archives never \
  --patch './Patches/' \
  --output './No-Intro/' \
  --dir-dat-name \
  --overwrite-invalid \
  --zip-exclude '*.{chd,iso}' \
  --reader-threads 4 \
  -v"

# Disc-based consoles, 4th+ generations
# Let maxcso calculate CSO CRC32s, don't checksum compressed discs (we only care about the contents)
eval "npx --yes igir@latest move test clean report \
  --dat './Redump*.zip' \
  --input './Redump/' \
  $INPUT_ARGS \
  --input-checksum-max CRC32 \
  --input-checksum-archives never \
  --patch './Patches/' \
  --output './Redump/' \
  --dir-dat-name \
  --overwrite-invalid \
  --only-retail \
  --single \
  --prefer-language EN \
  --prefer-region USA,WORLD,EUR,JPN \
  --prefer-revision newer \
  -v"

# MAME (arcade) collection
eval "npx --yes igir@latest move zip test clean \
  --dat './mame*.xml' \
  --dat './MAME*Rollback*.zip' \
  --input './MAME/' \
  $INPUT_ARGS \
  --input-checksum-quick \
  --input-checksum-archives never \
  --output './MAME/' \
  --dir-dat-name \
  --overwrite-invalid \
  --merge-roms merged \
  -v"