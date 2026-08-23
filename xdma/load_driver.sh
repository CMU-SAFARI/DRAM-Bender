#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_NAME="drambender_xdma"
MODULE_PATH="${SCRIPT_DIR}/xdma/${MODULE_NAME}.ko"

find_stream_pairs() {
  local dev_root="${1:-/dev}"
  local counterpart
  local node
  H2C_NODES=()
  C2H_NODES=()
  UNPAIRED_NODES=()

  shopt -s nullglob
  for node in "${dev_root}"/xdma*_h2c_*; do
    [[ -e "${node}" && ! -d "${node}" ]] || continue
    counterpart="${node/_h2c_/_c2h_}"
    if [[ -e "${counterpart}" && ! -d "${counterpart}" ]]; then
      H2C_NODES+=("${node}")
      C2H_NODES+=("${counterpart}")
    else
      UNPAIRED_NODES+=("${node}")
    fi
  done
  for node in "${dev_root}"/xdma*_c2h_*; do
    [[ -e "${node}" && ! -d "${node}" ]] || continue
    counterpart="${node/_c2h_/_h2c_}"
    if [[ ! -e "${counterpart}" || -d "${counterpart}" ]]; then
      UNPAIRED_NODES+=("${node}")
    fi
  done
  shopt -u nullglob

  [[ ${#H2C_NODES[@]} -gt 0 && ${#UNPAIRED_NODES[@]} -eq 0 ]]
}

rollback_loaded_module() {
  if rmmod "${MODULE_NAME}"; then
    echo "Rolled back the newly loaded ${MODULE_NAME} module." >&2
  else
    echo "Could not roll back ${MODULE_NAME}; it remains loaded." >&2
    echo "After checking for users, remove it explicitly with: rmmod ${MODULE_NAME}" >&2
  fi
}

fail_after_load() {
  echo >&2
  echo "Error: $1" >&2
  rollback_loaded_module
  echo " FAILED" >&2
  return 1
}

validate_insmod_args() {
  local argument
  for argument in "$@"; do
    case "${argument}" in
      enable_st_c2h_credit=*)
        echo "enable_st_c2h_credit is fixed at 1 for framed readback." >&2
        return 1
        ;;
    esac
  done
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [insmod-arg...]

Load an already-built XDMA kernel module. This script intentionally does not
build the driver. Build first with:

  ${SCRIPT_DIR}/build_driver.sh

Any extra arguments are passed to insmod. The loader fixes
enable_st_c2h_credit=1; callers cannot override it.
EOF
}

main() {
  local index owner

  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  validate_insmod_args "$@"

  if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
  fi

  if [[ ! -f "${MODULE_PATH}" ]]; then
    echo "Missing ${MODULE_PATH}." >&2
    echo "Run ${SCRIPT_DIR}/build_driver.sh first." >&2
    exit 1
  fi

  if [[ -d "/sys/module/${MODULE_NAME}" ]]; then
    echo "The ${MODULE_NAME} module is already loaded. Unload it explicitly with rmmod first." >&2
    exit 1
  fi

  if [[ -e /sys/bus/pci/drivers/xdma/module ]]; then
    owner="$(basename "$(readlink -f /sys/bus/pci/drivers/xdma/module)")"
    echo "The XDMA PCI driver is already registered by module ${owner}." >&2
    echo "Quiesce all clients and unload that module deliberately before replacing it." >&2
    exit 1
  fi

  echo -n "Loading ${MODULE_NAME} driver..."
  insmod "${MODULE_PATH}" "$@" enable_st_c2h_credit=1

  if [[ ! -d "/sys/module/${MODULE_NAME}" ]]; then
    echo >&2
    echo "Error: ${MODULE_NAME} did not appear in sysfs after insmod." >&2
    echo " FAILED" >&2
    exit 1
  fi

  if [[ ! -e /sys/bus/pci/drivers/xdma/module ]] ||
     [[ "$(readlink -f /sys/bus/pci/drivers/xdma/module)" != "/sys/module/${MODULE_NAME}" ]]; then
    fail_after_load "${MODULE_NAME} loaded, but it does not own the XDMA PCI driver."
    return 1
  fi

  if command -v udevadm >/dev/null 2>&1; then
    udevadm settle --timeout=10 || true
  fi

  if ! find_stream_pairs /dev; then
    fail_after_load "No complete XDMA H2C/C2H endpoint set appeared. Check the programmed bitstream, PCI IDs in xdma_mod.c, and udev/devtmpfs."
    return 1
  fi

  echo " DONE"
  for ((index = 0; index < ${#H2C_NODES[@]}; ++index)); do
    printf "Stream pair: %s / %s\n" "${H2C_NODES[index]}" "${C2H_NODES[index]}"
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
