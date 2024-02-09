#!/bin/zsh

mobileconfig_path="/Users/josh.litton/Downloads/WiFi - Return To Service [GGS Devices].mobileconfig"
plist=$(security cms -D -i "$mobileconfig_path" | xmllint --format -)
echo $plist | base64