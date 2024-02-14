#!/bin/bash
# Installs Pit Crew. Requires two arguments, the name of the libvirt domain to install the hooks to, and the word "real" to do a real installation (otherwise installs to ./fakedir)
set -e

#function cleanup { if [ -d workingCopy ]; then rm -r workingCopy; fi }
#trap cleanup EXIT
function showHelp { echo "INSTALL.sh takes 2 arguments; the name of a libvirt domain, and the word \"real\", without which the script will copy to a fake directory."; }

domain=$1
real=$2

if [ $real ]; then
	root=''
elif [[ ! $real || $real -ne "real" ]]; then
	root="fakedir"
fi

hooksDest=$root/etc/libvirt
hooksFinal="$hooksDest/hooks/qemu.d/$domain"
hookStartPath="$hooksFinal/prepare/begin"
hookStopPath="$hooksFinal/release/end"
gpusetDest=$root/usr/bin
pitcrewUnitDest=$root/etc/systemd/system

# i am incorrigible
snark='\033[4m'
bold='\033[1m'
chill='\033[0m'

if [ ! $domain ]; then
	echo "No libvirt domain was specified."
	showHelp
	exit 3
elif [ ! -f "/etc/libvirt/qemu/$domain.xml" ]; then
	echo "Domain $domain wasn't found in /etc/libvirt/qemu."
	exit 4
elif [ ! "$(whereis systemd | grep /usr/bin/systemd)" ]; then 
	echo "GPU Pit Crew requires systemd, but it wasn't found at /usr/bin/systemd."
	exit 5
elif [ ! "$(whereis -b libvirtd)" ]; then 
	echo -e "Libvirt isn't installed. You ${snark}might${chill} be lost."
	exit 5
fi
if [ ! "$UID" -eq 0 ]; then
	echo "Looks good, elevating..."
	exec sudo bash "$0" "$@"
fi

# Do The Do
[ $real ] || echo "Note, this will be a quasi-dry-run; you can find the created files in the 'fakedir' directory. To properly install, do \"./INSTALL.sh <domain> real\"."

# set up folder structure
destinations=($hooksDest $gpusetDest $pitcrewUnitDest)
for i in ${destinations[@]}; do
	if [ ! -d $i ]; then
		mkdir -p $i
	fi
done
echo -e "\n---"
set -x

rsync -varu hooks $hooksDest
rsync -varu gpuset.sh "$gpusetDest"
rsync -varu pitcrew.service "$pitcrewUnitDest"
rsync -varu --remove-source-files "$hooksDest/hooks/qemu.d/<vmname>/" "$hooksFinal"
#"""hey why don't you just use rsync if mv can't rename directories with stuff in them""" eat shit!!!!!
find $hooksDest -type d -empty -delete

#if this works i'm going to shit my whole ass off
chmod -v +x {$hooksDest/hooks/qemu,$hookStartPath/start.sh,$hookStopPath/stop.sh}
set +x

echo -e "--- \n\n Done! Do ${bold}systemctl daemon-reload${chill} and ${bold}systemctl enable --now pitcrew.service${chill} to enable Pit Crew, and restart pitcrew.service to manually reload it. To enable automatic GPU offload, uncomment the last line in ${bold}$hookStopPath/stop.sh.${chill}"
