#!/bin/bash 

# Debugging
# exec 19>/home/<yourname>/Desktop/startlogfile
# BASH_XTRACEFD=19
# set -x
###
# ^ I didn't use that while making this, they're part of Sebastian's base files. Use 'em if you like I'm not your dad
###

# Check if vfio is loaded.
if [ -z "$(lspci -vnn | grep vfio)" ]; then
	# Make a file that tells Pit Crew that we want to enable VFIO.
	if [ ! -f /etc/libvirt/request-passthrough ]; then
		touch /etc/libvirt/request-passthrough
	fi
	notify-send 'VM Starting...' 'The VM is starting. The display manager will now restart.'
	sleep 5
	systemctl restart pitcrew
fi






