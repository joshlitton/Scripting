#!/bin/sh

for package in /private/tmp/software/*.pkg; do
    sudo installer -pkg $package -target / -allowUntrusted
    sleep 1.0
    sudo rm $package
done


# for package in /tmp/loops/*.pkg; do
#     sudo installer -pkg $package -target /
#     sleep 1.0
#     sudo rm $package
# done
