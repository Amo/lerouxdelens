#!/usr/bin/env bash
set -euo pipefail

domain="${1:?domain required}"
hosts_file="/etc/hosts"
entry="127.0.0.1 ${domain}"

if grep -Eq "^[[:space:]]*127\\.0\\.0\\.1[[:space:]]+.*\\b${domain}\\b" "${hosts_file}"; then
  echo "${domain} already points to 127.0.0.1 in ${hosts_file}"
  exit 0
fi

echo "Adding ${domain} to ${hosts_file}"
echo "${entry}" | sudo tee -a "${hosts_file}" >/dev/null
echo "${domain} now points to 127.0.0.1"
