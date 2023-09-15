#!/bin/zsh


dialog="/usr/local/bin/dialog"
cmdfile="/private/var/tmp/command.log"
jsonfile="/private/var/tmp/dialog.json"

tee ${jsonfile} << EOF
{
	"title" : "Setup Screen",
	"blurscreen" : 1
}
EOF

${dialog} --jsonfile "${jsonfile}" &
wait
${dialog} --title none \
--style alert \
--button1text none \
--commandfile "${cmdfile}" \
--progress &

sleep 0.2
function doMore () {
	sleep 5
	echo "title: My title" >> ${cmdfile}
	echo "height: 400" >> ${cmdfile}
	echo "width: 200" >> ${cmdfile}
	echo "blurscreen: 0" >> ${cmdfile}
	echo "position: bottomleft" >> ${cmdfile}
}

doMore
wait

wait