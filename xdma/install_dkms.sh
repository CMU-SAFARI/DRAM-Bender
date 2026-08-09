#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dkms_registration_present() {
  local status_output="$1"
  [[ -n "${status_output//[[:space:]]/}" ]]
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--kernel-release <release>]

Perform one clean DKMS installation of the DRAM-Bender XDMA driver. The script
never replaces or removes an existing installation. Use uninstall_dkms.sh
explicitly before an intentional reinstall.
EOF
}

main() {
  local kernel_release=""
  local registered_status
  local source_dir
  local staged_source_dir
  local target_kernel

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kernel-release)
        kernel_release="${2:?missing value for --kernel-release}"
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

  target_kernel="${kernel_release:-$(uname -r)}"
  source_dir="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
  registered_status="$(dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" 2>/dev/null || true)"

  # Refuse before the first write. This is a clean-install operation, not an
  # updater, and its behavior is independent of DKMS 2.x/3.x status syntax.
  if dkms_registration_present "${registered_status}"; then
    echo "DKMS package ${PACKAGE_NAME}/${PACKAGE_VERSION} is already registered." >&2
    echo "Run ${SCRIPT_DIR}/uninstall_dkms.sh --remove-source before reinstalling." >&2
    exit 1
  fi
  if [[ -e "${source_dir}" || -L "${source_dir}" ]]; then
    echo "Source path already exists: ${source_dir}" >&2
    echo "Remove it explicitly with ${SCRIPT_DIR}/uninstall_dkms.sh --remove-source." >&2
    exit 1
  fi

  staged_source_dir="$(mktemp -d "/usr/src/.${PACKAGE_NAME}-${PACKAGE_VERSION}.XXXXXX")"
  trap 'rm -rf "${staged_source_dir}"' EXIT

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
    -C "${SCRIPT_DIR}" -cf - . | tar -C "${staged_source_dir}" -xf -

  mv "${staged_source_dir}" "${source_dir}"
  trap - EXIT

  dkms add -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
  dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${target_kernel}"

  # Publish required options before DKMS install runs depmod. An asynchronous
  # modalias load can therefore never observe the credit-disabled default.
  install -D -m 0644 \
    "${SCRIPT_DIR}/modprobe.d/drambender-xdma.conf" \
    "/etc/modprobe.d/drambender-xdma.conf"

  dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${target_kernel}"

  echo "Installed module drambender_xdma.ko for ${target_kernel}."
  echo "The installer did not replace a running driver; use load_driver.sh during a deliberate maintenance window."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
