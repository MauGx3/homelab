#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="/data/roms-unverified"
OUTPUT_DIR="/data/roms-verified"
DAT_DIR="/data/dats"

echo "== Checking DAT directory: $DAT_DIR =="

# 1. Make sure the DAT directory exists and isn't empty
if [ ! -d "$DAT_DIR" ]; then
    echo "ERROR: DAT directory not found: $DAT_DIR"
    exit 1
fi

shopt -s nullglob
DAT_FILES=("$DAT_DIR"/*.dat)

if [ ${#DAT_FILES[@]} -eq 0 ]; then
    echo "ERROR: No .dat files found in $DAT_DIR"
    exit 1
fi

# 2. Validate each DAT file
for dat in "${DAT_FILES[@]}"; do
    echo "Validating DAT: $(basename "$dat")"
    if ! head -n 1 "$dat" | grep -q '<?xml'; then
        echo "  ❌ ERROR: Not a valid XML DAT file."
        exit 1
    fi
    if ! grep -q '<datafile' "$dat"; then
        echo "  ❌ ERROR: Missing <datafile> tag — invalid DAT format."
        exit 1
    fi
    echo "  ✅ OK"
done

echo "== All DAT files validated successfully =="
echo

# 3. Run Igir process
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

time npx -y igir@latest \
    move \
    extract \
    report \
    test \
    -v
    # -d "${DAT_DIR}/" \
    -d /data/dats \
    # -i "${INPUT_DIR}/" \
    -i /data/roms-unverified \
    # -o "${OUTPUT_DIR}/{romm}/" \
    -o /data/roms-verified \
    --input-checksum-quick false \
    --input-checksum-min CRC32 \
    --input-checksum-max SHA256 \
    --only-retail
    # --report-output "/data/igir/report %dddd, %MMMM %Do %YYYY, %h:%mm:%ss %a.csv"

# time igir move extract report test -v -d /data/dats -i /data/roms-unverified -o /data/roms-verified --input-checksum-quick false --input-checksum-min CRC32 --input-checksum-max SHA256 --only-retail --report-output /data/igir/report_%dddd_%MMMM_%Do_%YYYY_%h:%mm:%ss_%a.csv