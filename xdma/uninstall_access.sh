#!/usr/bin/env bash

set -euo pipefail

GROUP_NAME="drambender"
RULE_NAME="70-drambender-xdma.rules"
RULE_DEST="/etc/udev/rules.d/${RULE_NAME}"

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

rm -f "${RULE_DEST}"
udevadm control --reload-rules
udevadm trigger --action=change --subsystem-match=xdma
udevadm settle

echo "Removed ${RULE_DEST}."
echo "The ${GROUP_NAME} group and its memberships were left intact intentionally."
