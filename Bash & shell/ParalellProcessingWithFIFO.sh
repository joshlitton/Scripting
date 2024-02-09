#!/bin/zsh

dialog="/usr/local/bin/dialog"
installomator="/usr/local/Installomator/Installomator.sh"
cmdfile="/private/var/tmp/command.log"
#jsonfile="/private/var/tmp/dialog.json"
arrCommands=("sleep 4" "sleep 6" "sleep 2")
declare -a arrBGPIDs
declare -a arrExitCodes

tee ${jsonfile} << EOF
{
	"title" : "Setup Screen",
	"blurscreen" : 0
}
EOF
#${dialog} --jsonfile "${jsonfile}" &
${dialog} --title none \
--width 600 \
--height 450 \
--button1text none \
--commandfile "${cmdfile}" \
--listitem "Command 1" \
--listitem "Command 2" \
--listitem "Command 3" \
--progress &
dialogPID=$!
sleep 0.2
echo "title: Dialog PID - ${dialogPID}" >> $cmdfile

writeToCommand() {
	echo "listitem: index: 1, status: fail" > $1
}
writeToCommand $cmdfile
#echo "listitem index: 1, status: pending" > "${cmdfile}"


# Use mktemp -u to create a unique temporary file pathway
# eg. "/var/folders/ym/hv76wn3x3q7_0ylw9jw0v0rc0000gp/T/tmp.hRT5uqVtCC"
my_pipe=$(mktemp -u)
# MKFIFO = Make First-In First-Out
# This spawns a 'named pipe'
# Named pipes are used for interprocess communication, think of it as a file that can be parsed or monitored by multiple processes
mkfifo "$my_pipe"
# Declare our trap to remove the temporary file on exit
trap 'rm -f "$my_pipe"' EXIT

# This function tails the named pipe and writes the data into a file
# $1 = The pipe/file to monitor
# $2 = The file to write to
tailFIFO () {
	tail -f $1 | while read -r line; do
		# Use bash inline over other binaries like cat / tr / sed for optimised processing
		index=${line%%:*}
		exit_code=${line#*:}
		echo "File Changed: $line"
		echo "index: $index"
		echo "exitcode: $exit_code"
		# Available status
		case $exit_code in
			# wait, success, fail, error, pending or progress: ##
			# Need to add other conditionals for different return codes
			0) status="success";;
			*) status="error" ;;
		esac
		# wait, success, fail, error, pending or progress: ##
		echo "listitem: index: $index, status: $status" >> $2
		#sleep 0.2
	done
}
# Swift Dialog format for list items
#listitem: [title: <title>|index: <index>], status: <status>, statustext: <text>

# Initiate the named pipe tail as a background process
tailFIFO $my_pipe $cmdfile &

# set i = 0; if i less than number of items in arrCommands; increment i by 1
for ((i=0; i<${#arrCommands[@]}; i++)); do
	echo "Running command: ${arrCommands[i]} in subshell"
	# `{ } &` syntax is used to group commands to be run in the same subshell
	{
		${arrCommands[i]}
		# We only use overwrite output to our named pipe as we don't want multiple lines. 
		echo "$i:$?" > "$my_pipe"
	} &
	# Store the PID of the background process
	#echo "PID: $!"
	arrBGPIDs[$i]=$!
	sleep 0.2
	echo "listitem: index: $i, status: wait, statustext: ${arrBGPIDs[$i]}" >> "$cmdfile"
	#sleep 0.2
done

sleep 10

# Wait will be required however need to kill swift dialog / tail or only wait for necessary processes

exit 0
#echo ${arrExitCodes[@]}

