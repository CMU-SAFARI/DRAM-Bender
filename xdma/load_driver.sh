#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_PATH="${SCRIPT_DIR}/xdma/xdma.ko"

usage() {
  cat <<EOF
Usage: $(basename "$0") [insmod-arg...]

Load an already-built XDMA kernel module. This script intentionally does not
build the driver. Build first with:

  ${SCRIPT_DIR}/build_driver.sh

Any extra arguments are passed to insmod after enable_st_c2h_credit=1.
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if [[ ! -f "${MODULE_PATH}" ]]; then
  echo "Missing ${MODULE_PATH}." >&2
  echo "Run ${SCRIPT_DIR}/build_driver.sh first." >&2
  exit 1
fi

if lsmod | grep -q '^xdma '; then
  echo "The xdma module is already loaded. Unload it explicitly with rmmod first." >&2
  exit 1
fi

echo -n "Loading xdma driver..."
insmod "${MODULE_PATH}" enable_st_c2h_credit=1 "$@"

if ! grep -qw xdma /proc/devices; then
  echo
  echo "Error: The kernel module loaded, but no xdma devices were recognized."
  echo " FAILED"
  exit 1
fi

echo " DONE"
