#!/bin/sh
# Automagically loads looking glass, Scream and virt-manager if a VM with passthrough enabled is running.
# Use your favourite autostart method on me. :3
if [ -f /run/libvirt/request-passthrough ]; then
	looking-glass-client &
	virt-manager &
	scream -i virbr0
fi