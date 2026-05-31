#!/usr/bin/env zsh

InstalledApps=(`ls /Applications/ | sed -e 's/ //' | tr '[:upper:]' '[:lower:]' | sed -e 's/\.app//'`)
InstallomatorLabels=(`/usr/local/Installomator/Installomator.sh`)

comm -12 <(printf "%s\n" "${InstalledApps[@]}" | sort) \
<(printf "%s\n" "${InstallomatorLabels[@]}" | sort)
