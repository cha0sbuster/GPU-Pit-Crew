# GPU Pit Crew 
### A hack by actuallyasriel

This is a set of components made with the intent of switching a graphics card from its default drivers to VFIO drivers without having to reboot or use a separate grub configuration. When set up, a hook will fire upon starting a VM (wherein a folder with the hooks exists in hooks/qemu.d with the name of said VM). The startup hook makes a file in /etc/libvirt, and triggers a small systemd unit to restart, which launches a script which *actually* does the driver handover.
It's a very roundabout way of getting the intended result, but it does work, and it works fairly consistently from my testing.
Note that this is NOT A COMPLETE SOLUTION! You're expected to have a working VFIO passthrough setup already! The point of this kit is to make controlling said passthrough more convenient.

While this baby is 100% Bash (with traces of systemd), I've only tested it on Debian 12 Bookworm. There's no reason it shouldn't work on any systemd-based distro, but if you don't cover your ass, you tend to shit yourself.

.............anyways,

## License
qemu.sh, in this repo, is part of VFIO-Tools, and should be retroactively considered licensed under the BSD-2 Clause License.

## Rationale
- What is this for?

GPUPC is for users of QEMU-KVM with GPU passthrough via VFIO, who have a dedicated graphics card (currently only NVIDIA is supported) which only ever outputs video from the guest, but may still need to do work on the host (e.g. CUDA) when the VM is shut off. It uses a systemd service to gracefully shut down the user's display manager, unload the old drivers and load the new ones via modprobe, and then re-enable the display manager, allowing `libvirtd`'s automatic management to take over the binding process without the need to write to files in `/sys` or use `virsh` commands in QEMU hooks, [which is dangerous.](https://www.libvirt.org/hooks.html#calling-libvirt-functions-from-within-a-hook-script) Notably, the DM must only restart when the VM boots; it's been observed, and since implemented, that it doesn't actually have to do that when the VM shuts down.

- Why systemd?

~~*You show me your working VFIO GPU passthrough on a distro rocking OpenRC, and I'll port GPUPC to it. Bet.*~~ I've already been challenged on this. I might actually have to follow through. ... We'll see.

Also, I needed an excuse to learn more about it. This was the perfect excuse. 

- Why not use [Bryan Steiner's hooks?](https://github.com/bryansteiner/gpu-passthrough-tutorial?tab=readme-ov-file#part1.2)

Bryan's solution is elegant and simple -- but it relies on `virsh`'s `nodedev-detach` and `nodedev-reattach`. Libvirt specifically says *not* to call back to Libvirt in hooks. While in many cases, this works and people have no trouble, it takes *one* thing going wrong with this approach for the whole thing to break. The original starting point for Pit Crew was troubleshooting a deadlock caused by using Steiner's hooks, which was fixed by doing `fuser -k /dev/nvidia0 && fuser -k /dev/nvidiactl`, which would cause another X server restart each time; but then the passthrough would start working normally. Automating this process produced the first iteration of `gpuset.sh`. It was then a simple matter of writing a small systemd unit to call `gpuset`, and connecting the hooks to that systemd unit instead of relying on `virsh nodedev-detach` to properly handle the driver switch, as clearly, it struggles with this on Nvidia cards, likely due to Nvidia's proprietary driver having unusually eager binding behavior.

- Why not use [VFIO-Tools?](https://github.com/PassthroughPOST/VFIO-Tools)
  
Without VFIO-Tools' hook helper, none of this would be possible (or at least, it would be far more annoying!) But its `vfioselect` script is very low-level; it operates by writing to `/sys` files, which always felt... sketchy to me. It may also be overwrought -- a few have observed that in many cases all that's needed is to bind/unbind `efifb` and kill the display manager. It is, however, far more elegant than what I've come up with. I have to respect the effort that went into making Bash so terse.
From what I understand, the reason for Steiner's solution (or the one he cribbed anyay), is that this can be dangerous, as it depends on modprobe rules being written correctly. The direct hook approach sought to use facilities that Libvirt provides to abstract the process. Unfortunately, it does so in a way that is unstable and highly vulnerable to edge-cases.

The goal of GPUPC is to ensure driver hotplugging won't be disturbed by any running graphical processes, as well as using systemd as a mechanism to allow it to fail in a graceful way which avoids locking up libvirtd, if it must fail. This has been done independently a couple of times, from what I've seen. (EFIFB is also not relevant for users with an integrated GPU.)

That being said, rebuilding GPUPC around `vfioselect` is something I'm considering.

## Installation
*An automated installer script has been included as of V2.* While it doesn't yet account for non-NVIDIA cards, it implements a workaround for some strange behavior I was having with LightDM. To use the automated installer, launch it with `./INSTALL.sh <domain> real`, where <domain> is the name of your VM as displayed in virsh/virt-manager. If you exclude `real`, it will install to a fake root. You could then browse around the installed files to check for problems with permissions, or double-check that the file structure matches what you expect. The installer requires you have rsync installed, but you almost certainly already do.

### Manual Installation
0. If you're using a dedicated AMD card, change the drivers in gpuset.sh accordingly. I forgot what the names of all of them were or else I'd just ship an alternative version. It's late. Don't @ me.
1. Make sure all the shell scripts are executable, because you know how Linux is.
2. Put gpuset.sh into /usr/bin. (Or anywhere else as long as you're willing to edit pitcrew.service to point to it.)
3. Put pitcrew.service into /etc/systemd/system.
4. Rename hooks/qemu.d/\<vmname\> with the name of the virtual machine you want to trigger passthrough. (You can make copies with different names if you want.)
5. Put the hooks folder in /etc/libvirt, merging with the existing hooks folder.
   
5a. If you want the driver to be automatically reloaded when the VM shuts down, uncomment the last line in stop.sh. (This should be configurable in a file in /etc/libvirt/hooks soon.)

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
