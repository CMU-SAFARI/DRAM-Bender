#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOVE_SOURCE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--remove-source]

Remove the DRAM-Bender XDMA DKMS package. Use --remove-source to also delete
the installed /usr/src source tree.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-source)
      REMOVE_SOURCE=1
      shift
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

REGISTERED_STATUS="$(dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" 2>/dev/null || true)"
if [[ -n "${REGISTERED_STATUS//[[:space:]]/}" ]]; then
  dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all
else
  echo "DKMS package ${PACKAGE_NAME}/${PACKAGE_VERSION} is not registered."
fi
rm -f "/etc/modprobe.d/drambender-xdma.conf"

if [[ "${REMOVE_SOURCE}" -eq 1 ]]; then
  rm -rf "/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
fi

echo "Removed the DKMS package and modprobe configuration."
echo "A currently loaded drambender_xdma module remains loaded until it is deliberately removed or the host reboots."
