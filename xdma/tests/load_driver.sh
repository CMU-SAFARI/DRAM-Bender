#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [interrupt-mode]

Compatibility entry point for the vendor test suite. The mode is one of:
  0  automatic interrupt selection (default)
  1  MSI
  2  legacy interrupt
  3  MSI-X
  4  polling

The supported loader never unloads a running driver automatically.
EOF
}

case "${1:-0}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  0)
    args=(interrupt_mode=0)
    ;;
  1)
    args=(interrupt_mode=1)
    ;;
  2)
    args=(interrupt_mode=2)
    ;;
  3)
    args=(interrupt_mode=3)
    ;;
  4)
    args=(poll_mode=1)
    ;;
  *)
    echo "Invalid interrupt mode: $1" >&2
    usage >&2
    exit 1
    ;;
esac

exec "${SCRIPT_DIR}/../load_driver.sh" "${args[@]}"
