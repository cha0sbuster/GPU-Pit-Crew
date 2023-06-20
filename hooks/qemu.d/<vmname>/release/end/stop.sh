#!/bin/bash

# Debugging
# exec 19>/home/asriel/Desktop/stoplogfile
# BASH_XTRACEFD=19
# set -x

# Bind EFI Framebuffer
# echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

# Remove request file
rm /etc/libvirt/request-passthrough
# Start display manager
notify-send '' 'Tiamat has shut down. GPU will be available when you restart X.'
