#!/bin/sh

labels=("googlechromepkg" "firefoxpkg" "" "")
notify=${11}

installo="/usr/local/Installomator/Installomator.sh"

for label in ${labels[@]}
do
    if [[ "${label}" = "" ]]
    then
        echo "Parameter not defined"
    else
        "${installo}" "${label}" NOTIFY="${notify}"
    fi
done