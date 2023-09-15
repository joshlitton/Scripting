#!/bin/sh

installer -pkg "/private/tmp/outset-2.0.6.pkg" -target /

cp -f "/private/tmp/InstallKeyboard.sh" "/usr/local/outset/login-every/InstallKeyboard.sh"

chown -R root:wheel "/usr/local/outset/login-every/InstallKeyboard.sh"
chmod 755 "/usr/local/outset/login-every/InstallKeyboard.sh"

rm -f "/private/tmp/InstallKeyboard.sh"
rm -f "/private/tmp/outset-2.0.6.pkg"

exit 0
