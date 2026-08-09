#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUP_NAME="drambender"
RULE_NAME="70-drambender-xdma.rules"
RULE_SOURCE="${SCRIPT_DIR}/udev/${RULE_NAME}"
RULE_DEST="/etc/udev/rules.d/${RULE_NAME}"
USERS=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [--user <login>]...

Install persistent non-root access to /dev/xdma* for members of the dedicated
${GROUP_NAME} group. Repeat --user to enroll more than one login.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      USERS+=("${2:?missing value for --user}")
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

for login in "${USERS[@]}"; do
  if ! id "${login}" >/dev/null 2>&1; then
    echo "Unknown login: ${login}" >&2
    exit 1
  fi
done

if ! getent group "${GROUP_NAME}" >/dev/null; then
  groupadd --system "${GROUP_NAME}"
fi

install -D -m 0644 "${RULE_SOURCE}" "${RULE_DEST}"

for login in "${USERS[@]}"; do
  usermod --append --groups "${GROUP_NAME}" "${login}"
done

udevadm control --reload-rules
udevadm trigger --action=change --subsystem-match=xdma
udevadm settle

echo "Installed ${RULE_DEST}."
if [[ ${#USERS[@]} -gt 0 ]]; then
  printf 'Added to %s: %s\n' "${GROUP_NAME}" "${USERS[*]}"
  echo "Those users must start a new login session before group membership takes effect."
else
  echo "Add authorized users with: usermod --append --groups ${GROUP_NAME} <login>"
fi
