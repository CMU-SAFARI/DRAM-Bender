#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_RELEASE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--kernel-release <release>]

Install the DRAM-Bender XDMA driver with DKMS. DKMS will rebuild the module for
future kernel updates.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel-release)
      KERNEL_RELEASE="${2:?missing value for --kernel-release}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if ! command -v dkms >/dev/null 2>&1; then
  echo "dkms is not installed." >&2
  exit 1
fi

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/dkms.conf"

SOURCE_DIR="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
rm -rf "${SOURCE_DIR}"
mkdir -p "${SOURCE_DIR}"

tar \
  --exclude='xdma/*.ko' \
  --exclude='xdma/*.o' \
  --exclude='xdma/.*.o' \
  --exclude='xdma/.*.o.cmd' \
  --exclude='xdma/.*.cmd' \
  --exclude='xdma/*.mod' \
  --exclude='xdma/*.mod.c' \
  --exclude='xdma/modules.order' \
  --exclude='xdma/Module.symvers' \
  -C "${SCRIPT_DIR}" -cf - . | tar -C "${SOURCE_DIR}" -xf -

dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all >/dev/null 2>&1 || true
dkms add -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"

if [[ -n "${KERNEL_RELEASE}" ]]; then
  dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KERNEL_RELEASE}"
  dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KERNEL_RELEASE}"
else
  dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
fi
