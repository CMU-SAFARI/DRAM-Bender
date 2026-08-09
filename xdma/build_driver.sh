#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_RELEASE="$(uname -r)"
KERNEL_DIR=""
DEBUG=0
CLEAN_ONLY=0
JOBS="$(nproc)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Compile the XDMA kernel module without loading it.

Options:
  --kernel-release <release>  Kernel release to build for.
                              Default: ${KERNEL_RELEASE}
  --kernel-dir <path>         Kernel build/header directory.
                              Default: /lib/modules/<release>/build
  --debug                     Enable XDMA debug logging at compile time.
  --clean                     Clean build products for the selected kernel and exit.
  -j, --jobs <count>          Parallel make jobs. Default: ${JOBS}
  -h, --help                  Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel-release)
      KERNEL_RELEASE="${2:?missing value for --kernel-release}"
      shift 2
      ;;
    --kernel-dir)
      KERNEL_DIR="${2:?missing value for --kernel-dir}"
      shift 2
      ;;
    --debug)
      DEBUG=1
      shift
      ;;
    --clean)
      CLEAN_ONLY=1
      shift
      ;;
    -j|--jobs)
      JOBS="${2:?missing value for --jobs}"
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

if [[ -z "${KERNEL_DIR}" ]]; then
  KERNEL_DIR="/lib/modules/${KERNEL_RELEASE}/build"
fi

if [[ ! -d "${KERNEL_DIR}" ]]; then
  echo "Kernel build directory not found: ${KERNEL_DIR}" >&2
  echo "Install matching kernel headers or pass --kernel-dir." >&2
  exit 1
fi

if [[ "${CLEAN_ONLY}" -eq 1 ]]; then
  make -C "${SCRIPT_DIR}/xdma" KVER="${KERNEL_RELEASE}" KDIR="${KERNEL_DIR}" clean
  exit 0
fi

echo "Building XDMA for kernel ${KERNEL_RELEASE}"
echo "Using kernel build directory ${KERNEL_DIR}"

make -C "${SCRIPT_DIR}/xdma" \
  KVER="${KERNEL_RELEASE}" \
  KDIR="${KERNEL_DIR}" \
  DEBUG="${DEBUG}" \
  -j"${JOBS}"

MODULE_PATH="${SCRIPT_DIR}/xdma/drambender_xdma.ko"

echo "Built ${MODULE_PATH}"

if command -v modinfo >/dev/null 2>&1; then
  echo "Module name: $(modinfo -F name "${MODULE_PATH}" || true)"
  echo "Module vermagic: $(modinfo -F vermagic "${MODULE_PATH}" || true)"
fi
