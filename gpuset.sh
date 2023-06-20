#!/bin/bash
# GPU Pit Crew -- Doing Totally Normal Things To Your Display Manager Since 2023
# an actuallyasriel hack

# sloppily determine what driver's loaded already
if [ ! -z "$(lspci -vnn | grep vfio)" ]; then
	mode="vfio"
else
	mode="nvidia"
fi

# sloppily determine what driver *ought* to be loaded
if [ -f /etc/libvirt/request-passthrough ]; then # this file was made by the script at hooks/qemu.d/<vmname>/prepare/begin/start.sh
	passthrough="true"
else
	passthrough="false"
fi

echo "mode: $mode"
echo "passthrough requested: $passthrough"

# the things that do the funny
function switch_nvidia() {
	echo "Unloading vfio..."
	modprobe -rf vfio_pci
	modprobe -rf vfio_iommu_type1
	modprobe -rf vfio
	echo "Loading nvidia..."
	modprobe drm
	modprobe drm_kms_helper
	modprobe i2c_nvidia_gpu
	modprobe nvidia
	modprobe nvidia_modeset
	modprobe nvidia_drm
	modprobe nvidia_uvm
}

function switch_vfio() {
	echo "Killing processes using the nvidia card..."
	fuser -k /dev/nvidia0	# nvidia needs a *bit* more coercing to let go of the damn gpu
	echo "Unloading nvidia..."
	modprobe -rf nvidia_uvm
    	modprobe -rf nvidia_drm
    	modprobe -rf nvidia_modeset
    	modprobe -rf nvidia
   	modprobe -rf i2c_nvidia_gpu
   	modprobe -rf drm_kms_helper
   	modprobe -rf drm
	echo "Loading vfio..."
	modprobe vfio
	modprobe vfio_pci
	modprobe vfio_iommu_type1
}

# determine whether or not we actually need to do anything (to avoid extraneous module manipulation)
if   [ $mode = "nvidia" ] && [ $passthrough = "true" ] ; then
	switch_vfio
elif [ $mode = "vfio" ] && [ $passthrough = "false" ] ; then
	switch_nvidia
else
	exit
fi
