#!/usr/bin/env bash
# @param {...string} $@ Input directories to merge into this collection
set -euo pipefail

# shellcheck disable=SC2064
trap "cd \"${PWD}\"" EXIT
cd "$(dirname "$0")"


# Treat every CLI argument as an input directory
INPUTS=()
for INPUT in "$@"; do
  INPUTS+=(--input "${INPUT}")
done

# Cartridge-based consoles, 1st-5th generations
npx --yes igir@latest move zip test clean report \
  --dat "./No-Intro*.zip" \
  --dat-name-regex-exclude "/encrypted|source code/i" \
  --input "./No-Intro/" \
  "${INPUTS[@]:-}" \
  `# Trust checksums in archive headers, don't checksum archives (we only care about the contents)` \
  --input-checksum-max CRC32 \
  --input-checksum-archives never \
  --patch "./Patches/" \
  --output "./No-Intro/" \
  --dir-dat-name \
  --overwrite-invalid \
  --zip-exclude "*.{chd,iso}" \
  --reader-threads 4 \
  -v

# Disc-based consoles, 4th+ generations
npx --yes igir@latest move test clean report \
  --dat "./Redump*.zip" \
  --input "./Redump/" \
  "${INPUTS[@]}" \
  `# Let maxcso calculate CSO CRC32s, don't checksum compressed discs (we only care about the contents)` \
  --input-checksum-max CRC32 \
  --input-checksum-archives never \
  --patch "./Patches/" \
  --output "./Redump/" \
  --dir-dat-name \
  --overwrite-invalid \
  --only-retail \
  --single \
  --prefer-language EN \
  --prefer-region USA,WORLD,EUR,JPN \
  --prefer-revision newer \
  -v

npx --yes igir@latest move zip test clean \
  `# Official MAME XML extracted from the progetto-SNAPS archive` \
  --dat "./mame*.xml" \
  `# Rollback DAT downloaded from Pleasuredome` \
  --dat "./MAME*Rollback*.zip" \
  --input "./MAME/" \
  "${INPUTS[@]}" \
  --input-checksum-quick \
  --input-checksum-archives never \
  --output "./MAME/" \
  --dir-dat-name \
  --overwrite-invalid \
  --merge-roms merged \
  -v