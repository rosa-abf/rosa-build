# -*- encoding : utf-8 -*-
DEFAULT_KS = <<-eos
timezone Europe/Moscow
auth --useshadow --enablemd5
selinux --disabled
firewall --enabled
firstboot --enabled
part / --size 8692

services --enabled=acpid,alsa,atd,atieventsd,avahi-daemon,dm,haldaemon,iptables,ip6tables,irqbalance,mandi,messagebus,msec,netfs,network,network-up,numlock,partmon,resolvconf,rpcbind,rsyslog,shorewall,sound,stop-bootlogd,udev-post,cups,mandrake_everytime,mandrake_firsttime
services --disabled=kudzu,sshd,crond,auditd,autofs,fuse,pptp,pppoe,ntpd

repo --name=Main       --baseurl=http://10.3.0.12/iso/repository/rpm/external/mdv/cooker/cooker/media/main/release/
#repo --name=Non-Free       --baseurl=file:///mnt/BIG/devel/cooker/#ARCH#/media/non-free/release
#repo --name=Livecd       --baseurl=file:///home/LIVE/rpm/i586/
repo --name=Rosa.add	--baseurl=http://10.3.0.12/iso/repository/Projects/mdv/sasha/ROSA.add.2011/RPMS
#repo --name=Contrib	--baseurl=http://10.3.0.12/iso/repository/rpm/external/mdv/cooker/cooker/media/contrib/release/

%packages
%include #PATH#/mdv-kde-one.lst.3
#%include #PATH#/mdv-base.lst
%end

%post

echo "ROSA Desktop 2011.beta" > /etc/redhat-release
echo "ROSA Desktop 2011.beta" > /etc/issue
echo "ROSA Desktop 2011.beta" > /etc/issue.net
echo "ROSA Desktop 2011.beta" > /etc/system-release


#### WORKAROUND FOR DBUS ###
/usr/sbin/useradd messagebus -d / -s /bin/false
#### END OF IT ####

echo ""
/bin/ls -l /boot/
echo ""
echo "###################################### Make initrd symlink >> "
echo ""

/usr/sbin/update-alternatives --set mkinitrd /sbin/mkinitrd-dracut
rm -rf /boot/initrd-*


# adding life user
/usr/sbin/adduser live
/usr/bin/passwd -d live
/bin/mkdir -p /home/live
/bin/cp -rfT /etc/skel /home/live/
/bin/chown -R live:live /home/live


# ldetect stuff
/usr/sbin/update-ldetect-lst

# setting up network manager by default
pushd /etc/sysconfig/network-scripts
for iface in eth0 wlan0; do
	cat > ifcfg-$iface << EOF
DEVICE=eth0
ONBOOT=yes
NM_CONTROLLED=yes
EOF
done
popd
#### workaround for NETWORKMANAGER

systemctl enable networkmanager.service

### END OF IT

# kde look-and-feel, should do into kde-common package
#sed -i 's/widgetStyle=iaorakde/widgetStyle=qtcurve/g' /var/lib/mandriva/kde4-profiles/common/share/config/kdeglobals
#sed -i 's/colorScheme=Ia Ora Smooth/colorScheme=Norway/g' /var/lib/mandriva/kde4-profiles/common/share/config/kdeglobals

# default background
pushd /usr/share/mdk/backgrounds/
ln -s rosa.jpg default.jpg
#popd

# mtab
pushd /etc/
ln -sf /proc/mounts mtab
popd

# 

#
# kernel
#

#
# Sysfs must be mounted for dracut to work!
#
mount -t sysfs /sys /sys

pushd /lib/modules/
KERNEL=$(echo *)
popd
echo
echo Generating kernel. System kernel is `uname -r`, installed kernels are:
rpm -qa kernel-*
echo Detected kernel version: $KERNEL

/sbin/dracut --add-drivers "sr-mod" /boot/initramfs-$KERNEL.img $KERNEL
ls -l /boot/

echo

#
#
#
# echo
# echo
# echo "Giving you a shell to fix stuff, good luck!"
# echo
# echo
# echo

# /bin/bash

echo ""
echo "###################################### Build ISO >> "
echo ""

%post --nochroot

    cp -rfT 	#PATH#/extraconfig/etc $INSTALL_ROOT/etc/

    cp -f 		#PATH#/root/GPL $LIVE_ROOT/
    mkdir -p 	$LIVE_ROOT/Addons
    cp 	  		/usr/bin/livecd-iso-to-disk			$LIVE_ROOT/Addons/
    chmod +x 	$LIVE_ROOT/Addons/livecd-iso-to-disk
    rpm --root $INSTALL_ROOT -qa | sort > $LIVE_ROOT/rpm.lst

%end

eos

DEFAULT_MENU=<<-eos
<?xml version="1.0"?>
<menu_config>
    <welcome_message>
        Welcome to
    </welcome_message>
    <product_name>
	ROSA 2011 Beta
    </product_name>
  <item name="Launch system">
    vga=788
    desktop
    nopat
    rd_NO_LUKS
    rd_NO_MD
    noiswmd
    splash=silent
  </item>
  <item name="Install system">
    vga=788
    desktop
    nopat
    rd_NO_LUKS
    rd_NO_MD
    noiswmd
    splash=silent
    install
  </item>
  <background_img_path>
	/home/LIVE/ROSA.2011/welcome.jpg
  </background_img_path>
  <font_path>
    /home/LIVE/ROSA.2011/cyra8x16.psf
  </font_path>
</menu_config>
eos

DEFAULT_COUNTER=<<-eos
63
eos

DEFAULT_BUILD=<<-eos
#!/bin/sh

#ARCHS="i586 x86_64"
#ARCHS="i586"

#if [ ! "$UID" = "0" ]; then#
#	echo "Restarting as root.."
#	exec sudo $0
#fi

# a temporary hack to make python 2.6 work
export PYTHONPATH=/usr/lib/python2.6/site-packages/

DIRNAME=$(dirname $0)
cd $DIRNAME

build_root="/home/LIVE/"

d=`date +%Y.%m.%d-%H.%M`

product_id="ROSA.2011"
product_name_file="${build_root}/${product_id}/.name.txt" ; touch ${product_name_file}

#ks="${build_root}/${product_id}/.ks"

ks="${build_root}/${product_id}/.ks"
counter="${build_root}/${product_id}/.counter"
menu="${build_root}/${product_id}/.menu.xml"

touch ${counter}

i=`cat ${counter}`
i=`expr $i + 1`

echo $i > ${counter}

echo "$i.$d" > ${build_root}/${product_id}/version.txt

# build different architectures

#for arch in $ARCHS; do
	cp -f ${ks}.template ${ks}
#	sed -i -e "s:#ARCH#:$arch:g" ${ks}
	sed -i -e "s:#PATH#:${build_root}/${product_id}:g" ${ks}
	sed -i -e "s:#PATH#:${build_root}/${product_id}:g" ${menu}

	mkdir -p $build_root/iso/${product_id}/
	# run with lower priority
	livecd-creator --config=${ks} --fslabel=${product_id}.$i --menu-config=${build_root}/${product_id}/.menu.xml

	mv ${product_id}.$i.iso $build_root/iso/${product_id}/
	#md5sum  /iso/${product_id}/${product_id}.$i.iso > /iso/${product_id}/${product_id}.$i.iso.md5sum

	echo ""
	echo "          ALL DONE!        $build_root/iso/${product_id}/${product_id}.$i.iso"
	echo ""
eos
