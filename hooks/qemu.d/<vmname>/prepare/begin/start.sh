#!/bin/bash 

# Debugging
# These lines output Bash trace info to a file on the desktop when uncommented.
# Because I can't be sure that QEMU hooks have tilde expansion, you'll have to replace <USER>. My bad.
# exec 19> /home/<USER>/Desktop/startlogfile 
# BASH_XTRACEFD=19
# set -x

# Check if vfio is loaded.
if [ -z "$(lspci -vnn | grep vfio)" ]; then
	# Make a file that tells Pit Crew that we want to enable VFIO.
	if [ ! -f /run/libvirt/request-passthrough ]; then
		touch /run/libvirt/request-passthrough
	fi
	echo "Restarting pitcrew.service"
	sleep 5
	systemctl restart pitcrew
fi
