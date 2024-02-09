#!/bin/zsh

dialog="/usr/local/bin/dialog"
installomator="/usr/local/Installomator/Installomator.sh"
IFS=","
commands=("$installomator googlechrome DEBUG=1","$dialog --test-mode","$installomator firefox DEBUG=1")

i=1
for command in ${commands[@]}; do
	echo "$command" | bash > /dev/null 2>&1 &
	pid=$!
	PIDS[$i]=${pid}
	echo "${pid} stored in array at index: $i"
	((i+=1))
done

echo "Finished running subprocesses"

i=1
# WHILE P


# While STATUS ARRAY count != PID COUNT
# if [[ pgrep -p $process ]]; then  # If I find the PID is running
# Do nothing
# else
# Get the exit code of PID


for process in ${PIDS[@]}; do
	echo "Checking status for pid: ${process}"
	wait "${process}"
	STATUS[$i]=$?
	((i+=1))
done

i=1
for ecode in ${STATUS[@]}; do
	echo "$i exit code = $ecode"
	((i+=1))
done


exit 0
$installomator googlechrome --DEBUG=1 &
bgpid1=$!
$dialog --test-mode --moveable &
bgpid2=$!

until $(ps -o pid= -p $bgpid1); do
	echo "$bgpid1 is running..."
done

echo "$bgpid1 & $bgpid2"

echo "PID 1"
ps -p $bgpid1
echo "PID 2"
ps -p $bgpid2


wait