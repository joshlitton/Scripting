#!/bin/bash

# Config
DOMAIN="trinity.wa.edu.au"
CSV_FILE="dnsrecords.csv"
NAMESERVERS=(
  "ns1-08.azure-dns.com"
  "ns2-08.azure-dns.net"
  "ns3-08.azure-dns.org"
  "ns4-08.azure-dns.info"
)

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check CSV exists
if [ ! -f "$CSV_FILE" ]; then
  echo "Error: CSV file '$CSV_FILE' not found."
  exit 1
fi

echo "========================================"
echo " DNS Record Test: $DOMAIN"
echo " $(date)"
echo "========================================"

for NS in "${NAMESERVERS[@]}"; do
  echo -e "\n${YELLOW}--- Nameserver: $NS ---${NC}"

  # Read CSV, skip header row
  tail -n +2 "$CSV_FILE" | while IFS=',' read -r HOST RECORD_TYPE; do
    # Trim whitespace
    HOST=$(echo "$HOST" | tr -d '[:space:]')
    RECORD_TYPE=$(echo "$RECORD_TYPE" | tr -d '[:space:]\r')

    # Build query - @ or blank means apex
    if [ "$HOST" == "@" ] || [ -z "$HOST" ]; then
      QUERY="$DOMAIN"
    else
      QUERY="$HOST.$DOMAIN"
    fi

    RESULT=$(dig @"$NS" "$QUERY" "$RECORD_TYPE" +short 2>&1)

    if [ -z "$RESULT" ]; then
      echo -e "  ${RED}✗${NC} $RECORD_TYPE $QUERY → (no result)"
    else
      echo -e "  ${GREEN}✓${NC} $RECORD_TYPE $QUERY →"
      echo "$RESULT" | while read -r line; do
        echo "      $line"
      done
    fi
  done
done

echo -e "\n========================================"
echo " Done"
echo "========================================"