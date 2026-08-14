#!/usr/bin/env bash
# Apply the DRAM Bender PHY calibration patches to the generated MIG
# sources. Safe to re-run; only patches the PHYs whose IP output has been
# generated. Prints PATCHES_OK on success.
set -u
cd "$(dirname "$0")"

status=0
applied=0
skipped=0

# apply_section <patch> <target-file> <already-patched-marker>
apply_section() {
    local p="$1" target="$2" marker="$3"
    [ -f "$target" ] || return 0        # this PHY was not generated
    sed -i 's/\r$//' "$target"          # MIG emits CRLF; patches are LF
    if grep -q "$marker" "$target"; then
        echo "already patched: $target"
        skipped=$((skipped + 1))
        return 0
    fi
    # keep only the file section of the multi-file patch for this target
    if awk -v t="$target" '/^--- /{keep = (index($0, t) > 0)} keep' "$p" \
            | patch -p0 --forward --batch; then
        applied=$((applied + 1))
    else
        echo "PATCH_FAILED: $p -> $target (see .rej)" >&2
        status=1
    fi
}

for phy in phy_rdimm_x8_dual phy_ddr4 phy_ddr4_udimm; do
    cal=U250.srcs/sources_1/$phy/rtl/cal
    apply_section patches/rd_en.patch "$cal/ddr4_v2_2_cal_rd_en.sv" \
                  'rsMask\[0:15\]'
    apply_section patches/write.patch "$cal/ddr4_v2_2_cal_write.sv" \
                  'FABRIC_CASSLOT1'
done

if [ "$applied" -eq 0 ] && [ "$skipped" -eq 0 ]; then
    echo "PATCH_FAILED: no generated PHY sources found;" \
         "generate IP output products first" >&2
    exit 1
fi
[ "$status" -eq 0 ] && echo "PATCHES_OK (applied=$applied, already-patched=$skipped)"
exit $status
