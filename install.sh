#!/bin/sh
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v apk >/dev/null 2>&1; then
  echo "Installing LanGuard Pro using apk..."
  apk add --allow-untrusted "$DIR/dist/languard-pro-2026.06.16-r1.apk"
elif command -v opkg >/dev/null 2>&1; then
  echo "Installing LanGuard Pro using opkg..."
  opkg install "$DIR/dist/languard-pro_2026.06.16-r1_all.ipk"
else
  echo "No supported package manager found. Need apk or opkg."
  exit 1
fi

echo "Installed."
echo "Open: http://192.168.10.1/cgi-bin/languard-login.sh"
