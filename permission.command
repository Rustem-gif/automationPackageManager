#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1

echo "Fixing permissions for *.command files in: $(pwd)"
find . -maxdepth 1 -name "*.command" -exec chmod +x {} \;

echo "Done."
read -p "Press [Enter] to close..."

