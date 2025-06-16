#!/bin/bash

chromeApp="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
siteToOpen="https://fast.com"

"${chromeApp}" --kiosk \
--start-maximized \
--start-fullscreen \
--no-default-browser-check \
--no-first-run \
--app "${siteToOpen}"