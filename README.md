# GPU Pit Crew 
### A hack by actuallyasriel

This is a set of components made with the intent of switching a graphics card from its default drivers to VFIO drivers without having to reboot or use a separate grub configuration. When set up, a hook will fire upon starting a VM (wherein a folder with the hooks exists in hooks/qemu.d with the name of said VM). The startup hook makes a file in /etc/libvirt, and triggers a small systemd unit to restart, which launches a script which *actually* does the driver handover.
It's a very roundabout way of getting the intended result, but it does work, and it works fairly consistently from my testing.
Note that this is NOT A COMPLETE SOLUTION! You're expected to have a working VFIO passthrough setup already! The point of this kit is to make controlling said passthrough more convenient.

While this baby is 100% Bash (with traces of systemd), I've only tested it on Debian 12 Bookworm. There's no reason it shouldn't work on any systemd-based distro, but if you don't cover your ass, you tend to shit yourself.

.............anyways,

## License
qemu.sh, in this repo, would eventually become part of VFIO-Tools, and should be retroactively considered licensed under the BSD-2 Clause License. (Truthfully, after discovering this, I would recommend... maybe just using that.)

## Installation
*An automated installer script has been included as of V2.* While it doesn't yet account for non-NVIDIA cards, it implements a workaround for some strange behavior I was having with LightDM. To use the automated installer, launch it with `./INSTALL.sh <domain> real`, where <domain> is the name of your VM as displayed in virsh/virt-manager. If you exclude `real`, it will install to a fake root, which might come in handy for testing. The installer requires you have rsync installed, but you almost certainly already do.

### Manual Installation
0. If you're using a dedicated AMD card, change the drivers in gpuset.sh accordingly. I forgot what the names of all of them were or else I'd just ship an alternative version. It's late. Don't @ me.
1. Make sure all the shell scripts are executable, because you know how Linux is.
2. Put gpuset.sh into /usr/bin. (Or anywhere else as long as you're willing to edit pitcrew.service to point to it. Didn't think so.)
3. Put pitcrew.service into /etc/systemd/system.
4. Rename hooks/qemu.d/\<vmname\> with the name of the virtual machine you want to trigger passthrough. (You can make copies with different names if you want.)
5. Put the hooks folder in /etc/libvirt, merging with the existing hooks folder.
   
5a. If you want the driver to be automatically reloaded when the VM shuts down, uncomment the last line in stop.sh. (This will be configurable eventually. Maybe. I'll have a go.)

When you're done, you should have these files, wherein \<vmname\> is your VM:
```
/etc/libvirt/hooks/qemu.d/<vmname>/prepare/begin/start.sh
/etc/libvirt/hooks/qemu.d/<vmname>/release/end/stop.sh
/etc/systemd/system/pitcrew.service
/usr/bin/gpuset.sh
```
6. Do `sudo systemctl restart libvirtd` and start your VM.
7. Pray.

Your display manager should restart, and depending on your setup you'll either have to log in again or you'll be plopped back into your desktop. virt-manager will be closed if you use it, but when you open it you should see that the VM has started, and your connected monitor (or the Looking Glass instance you've no doubt started already) should light up in short order. `lspci -v` should show that `vfio-pci` is now in use for your graphics card.

I won't say it'll work great, or at all, but it *should* be pretty easy to troubleshoot if something goes wrong and it's my fault, provided you've seen a systemd unit file in your life. Maybe keep a copy of the files around to hack at so you don't have to dick around your filesystem as many times as I have while writing this.

Godspeed.
