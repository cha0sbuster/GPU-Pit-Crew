#!/bin/bash 

# Debugging
# These lines output Bash trace info to a file on the desktop when uncommented.
# Because I can't be sure that QEMU hooks have tilde expansion, you'll have to replace <USER>. My bad.
# exec 19> /home/<USER>/Desktop/startlogfile 
# BASH_XTRACEFD=19
# set -x

# Bind EFI Framebuffer. This is disabled on my system as EFIFB doesn't work for me and I use an integrated GPU anyways. But I figure it's less effort to keep it in.
# echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

# Remove request file. This should just no-op if the file doesn't exist so w/e.
rm /run/libvirt/request-passthrough

# Uncomment this line to automatically restart the pitcrew service. From testing, the DM won't restart automatically when switching *off* VFIO, but if you're tweaking things on your VM, it'd be handy to avoid restarting it on every boot.

# systemctl restart pitcrew 

