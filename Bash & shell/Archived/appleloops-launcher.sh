#!/bin/bash
# https://github.com/carlashley/appleloops/wiki

dest="/Library/Application Support/kcc"
loops="$dest/appleloops-master/appleLoops"
#cache="http://10.42.11.1:51186"
# Automatically determine caching server location.
cache=$(AssetCacheLocatorUtil 2>&1 | awk '/guid / { gsub(",", "", $4); print $4}' | uniq | sed -n 1p)
if [[ "$cache" -eq null ]]; then
	echo "Caching Server Not Found! Running direct mode."
	python "$loops" --deployment -a garageband -qmou
else
	cache="http://$cache"
	echo "Caching server found at $cache. Running cache mode."
	python "$loops" --deployment -a garageband -c "$cache" -qmou
fi

# -q | Quiet Mode, minimal output to stdout
# -m | Install the mandatory loops only
# -o | Install the optional loops (use with -m)
# -u | Allow untrusted packages

exit 0
