#!/bin/zsh

# VERSION:  1.1 
# AUTHOR:   Josh Litton
# Currently only supports Device-Based profiles

profileName="${4}"		          # Profile Name:
#profileName="WaitForProfile"    # For Testing
runMode="${5}"                  # Wait for profile to be: [installed (default)/ uninstalled]
${runMode:="installed"}        # Default = installed if nothing specified
timer=${6}				              # How long to wait (in seconds
${timer:=60}                    # Default = 60s if nothing specified

if [[ -z $profileName ]]; then
	echo "Profile Name cannot be blank, exiting"
	exit 9
else
  i=0
  if [[ "$runMode" == "uninstalled" ]]; then
    echo "Checking if $profileName is $runMode, allowing ${timer}s"
    while /usr/bin/profiles show | grep "${profileName}"; do
      ((i++))
      if (( $i > $timer )); then
        echo "Reached specified timer: ${timer}s"
        exit 4
      else 
        echo "Loop $i"
      fi
      sleep 1
    done
  elif [[ "$runMode" == "installed" ]]; then
    echo "Checking if $profileName is $runMode, allowing ${timer}s"
    until /usr/bin/profiles show | grep "${profileName}"; do
      ((i++))
      if (( $i > $timer )); then
        echo "Reached specified timer: ${timer}s"
        exit 4
      else 
        echo "Loop $i"
      fi
      sleep 1
    done
  else
    echo "$runMode not recognized"
  fi
fi
echo "$profileName is $runMode"
exit 0