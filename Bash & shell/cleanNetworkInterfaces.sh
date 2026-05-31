#!/bin/zsh
set -e

ADAPTERS_TO_REMOVE=()
while IFS= read -r adapter; do
  ADAPTERS_TO_REMOVE+=("$adapter")
done < <(networksetup -listallnetworkservices | sed '1d; s/^[*] *//' | grep -F 'USB 10/100/1000 LAN')

echo "Removing specified network services..."
echo

for adapter in "${ADAPTERS_TO_REMOVE[@]}"; do
  echo "→ Removing: $adapter"
  networksetup -deletepppoeservice "$adapter"
done

echo
echo "Done."
#echo "Current network services:"
#networksetup -listallnetworkservices | sed '1d'