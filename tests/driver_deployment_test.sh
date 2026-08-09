#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${1:?source directory is required}"

for script in install_dkms.sh uninstall_dkms.sh install_access.sh uninstall_access.sh load_driver.sh; do
  if [[ ! -x "${SOURCE_DIR}/xdma/${script}" ]]; then
    echo "Deployment script is not executable: xdma/${script}" >&2
    exit 1
  fi
done

require_literal() {
  local file="$1"
  local literal="$2"
  if ! grep -Fq -- "${literal}" "${SOURCE_DIR}/${file}"; then
    echo "Missing deployment contract in ${file}: ${literal}" >&2
    exit 1
  fi
}

reject_literal() {
  local file="$1"
  local literal="$2"
  if grep -Fq -- "${literal}" "${SOURCE_DIR}/${file}"; then
    echo "Stale deployment contract in ${file}: ${literal}" >&2
    exit 1
  fi
}

require_literal xdma/xdma/Makefile 'TARGET_MODULE:=drambender_xdma'
require_literal xdma/README.md 'Linux `5.4` and `7.0`'
require_literal xdma/dkms.conf 'PACKAGE_VERSION="0.1.0"'
require_literal xdma/dkms.conf 'BUILT_MODULE_NAME[0]="drambender_xdma"'
require_literal xdma/load_driver.sh 'MODULE_NAME="drambender_xdma"'
require_literal xdma/xdma/xdma_mod.c '#define DRV_MODULE_NAME'
require_literal xdma/xdma/xdma_mod.c '"xdma"'
require_literal xdma/xdma/xdma_cdev.h '#define XDMA_NODE_NAME'
require_literal xdma/xdma/xdma_cdev.h '"xdma"'
require_literal xdma/modprobe.d/drambender-xdma.conf \
  'options drambender_xdma enable_st_c2h_credit=1'
require_literal xdma/udev/70-drambender-xdma.rules \
  'SUBSYSTEM=="xdma", KERNEL=="xdma*", GROUP="drambender", MODE="0660"'
require_literal xdma/install_dkms.sh 'dkms_registration_present'
reject_literal xdma/install_dkms.sh 'dkms remove'
reject_literal xdma/install_dkms.sh ' --force'
require_literal xdma/readme.txt 'sudo ./load_driver.sh poll_mode=1'
reject_literal xdma/readme.txt 'insmod xdma/'

provenance_files=(
  tests/board_tests/multi_endpoint_interrupt_test.py
  tests/board_tests/sibling_reset_isolation_test.py
  tests/board_tests/u200_readback_benchmark.py
  tests/board_tests/u200_readback_benchmark.cpp
)
for file in "${provenance_files[@]}"; do
  require_literal "${file}" drambender_xdma
  reject_literal "${file}" /sys/module/xdma
  reject_literal "${file}" 'module_provenance("xdma")'
  reject_literal "${file}" 'module_json("xdma")'
done

# Exercise paired endpoint discovery without hardware or privilege.
# shellcheck disable=SC1091
source "${SOURCE_DIR}/xdma/load_driver.sh"
test_root="$(mktemp -d)"
trap 'rm -f "${test_root}/xdma7_h2c_1" "${test_root}/xdma7_c2h_1" "${test_root}/xdma9_c2h_0"; rmdir "${test_root}"' EXIT
if find_stream_pairs "${test_root}"; then
  echo "Endpoint discovery accepted an empty device directory." >&2
  exit 1
fi
touch "${test_root}/xdma7_h2c_1"
if find_stream_pairs "${test_root}"; then
  echo "Endpoint discovery accepted an unpaired H2C node." >&2
  exit 1
fi
touch "${test_root}/xdma7_c2h_1"
find_stream_pairs "${test_root}"
[[ ${#H2C_NODES[@]} -eq 1 ]]
[[ "${H2C_NODES[0]}" == "${test_root}/xdma7_h2c_1" ]]
[[ "${C2H_NODES[0]}" == "${test_root}/xdma7_c2h_1" ]]
touch "${test_root}/xdma9_c2h_0"
if find_stream_pairs "${test_root}"; then
  echo "Endpoint discovery accepted an orphan C2H node." >&2
  exit 1
fi
rm -f "${test_root}/xdma9_c2h_0"

require_literal xdma/load_driver.sh \
  'fail_after_load "No complete XDMA H2C/C2H endpoint set appeared.'

# Verify that a post-insmod validation failure targets only the module this
# loader owns, without invoking the real privileged command.
rollback_target=""
rmmod() {
  rollback_target="$1"
}
if fail_after_load "offline rollback test" 2>/dev/null; then
  echo "Post-load failure unexpectedly reported success." >&2
  exit 1
fi
[[ "${rollback_target}" == drambender_xdma ]]

validate_insmod_args interrupt_mode=3
if validate_insmod_args enable_st_c2h_credit=0 2>/dev/null; then
  echo "Loader accepted an override that disables required C2H credits." >&2
  exit 1
fi

# DKMS 2.8 uses comma-separated status while newer DKMS releases may use a
# package/version prefix. Clean install rejects either without parsing it.
# shellcheck disable=SC1091
source "${SOURCE_DIR}/xdma/install_dkms.sh"
dkms_registration_present \
  'drambender-xdma, 0.1.0, 5.4.0-216-generic, x86_64: installed'
dkms_registration_present \
  'drambender-xdma/0.1.0, 7.0.0-28-generic, x86_64: installed'
if dkms_registration_present $' \n\t'; then
  echo "Whitespace-only DKMS status was treated as a registration." >&2
  exit 1
fi

echo "DRAM-Bender driver deployment contract: PASS"
