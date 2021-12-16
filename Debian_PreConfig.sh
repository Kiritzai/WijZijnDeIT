#!/bin/bash

set +H

# Actual Command to Run
# bash <(wget --no-cache -O - https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_PreConfig.sh)
# curl -sSL https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_PreConfig.sh | bash


################
## Parameters ##
################

# Software
SOFTWARE="PreConfig"


############################
#
## Installation
#
############################

clear
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

BANNER=$(cat <<EOF
	__        ___  _ ______  _       ____         ___ _____
	\ \      / (_)(_)__  (_)(_)_ __ |  _ \  ___  |_ _|_   _|
	 \ \ /\ / /| || | / /| || | '_ \| | | |/ _ \  | |  | |
	  \ V  V / | || |/ /_| || | | | | |_| |  __/_ | |  | |
	   \_/\_/  |_|/ /____|_|/ |_| |_|____/ \___(_)___| |_|
	            |__/      |__/    ${SOFTWARE} Installation
 
 
EOF
)
echo "$BANNER"
read -s -p $'\tPress enter to continue...\n' -n 1 -r

############################
#
## Parameters
#
############################

# Log file
logfile="$PWD/log.log"

# Log execute
exec 3>&1 1>>${logfile} 2>&1

function message {
	logdate=$(date "+%d %b %Y %H:%M:%S")
    echo "${logdate} :: $1" | tee /dev/fd/3
}


main () {
	clear
	echo "$BANNER"
	changeSources

	clear
	echo "$BANNER"
	installUtilities
	
	clear
	echo "$BANNER"
	setSudo

	clear
	echo "$BANNER"
	changeGrub

	clear
	echo "$BANNER"
    disableWrites

	clear
	echo "$BANNER"
    smBusFix

	clear
	echo "$BANNER"
	changeMotd

	exit
}

function changeSources {

	message "Adjusting sources"

	DEBIAN_FRONTEND=noninteractive apt -yqq clean
	rm /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ stable contrib main non-free" | tee /etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ stable contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb http://security.debian.org/debian-security stable-security contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb-src http://security.debian.org/debian-security stable-security contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ stable-updates contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ stable-updates contrib main non-free" | tee -a /etc/apt/sources.list
	#echo "deb http://deb.debian.org/debian stable-backports main" > /etc/apt/sources.list.d/backports.list
	DEBIAN_FRONTEND=noninteractive apt -yqq update
	#DEBIAN_FRONTEND=noninteractive apt -yqq install --reinstall dpkg libc-bin 
	DEBIAN_FRONTEND=noninteractive apt -yqq update
	DEBIAN_FRONTEND=noninteractive apt -yqq upgrade
	DEBIAN_FRONTEND=noninteractive apt -yqq autoremove
}

function installUtilities {

    message "Installing packages... this can take a while!"

	DEBIAN_FRONTEND=noninteractive \
	apt-get -yqq install  \
	mlocate \
	open-vm-tools \
	sudo \
	curl \
    git
	
    # Update Locate datebase after installation
	updatedb

}

function setSudo {

    message "Setting Sudo"

	echo "beheer    ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/010_beheer-nopasswd
}

function changeGrub {

    message "Change Grub"

	sed -i 's/GRUB_TIMEOUT=./GRUB_TIMEOUT=0/g' /etc/default/grub
	#sed -i 's/GRUB_CMDLINE_LINUX=""./GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
	update-grub
}

function disableWrites {

    message "Disable writes on storage"

	if grep -iRlq "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" /etc/fstab; then
		number=$(grep -iRn "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" /etc/fstab | cut -d: -f1)
		sed -i "$number,\$d" /etc/fstab
	fi

	echo "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0" |tee -a /etc/fstab
	echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=2g 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/run tmpfs defaults,noatime,nosuid,mode=0755,size=200m 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/spool/mqueue tmpfs defaults,noatime,nosuid,mode=0700,gid=12,size=300m 0 0" | tee -a /etc/fstab
}

function smBusFix {

    message "Fix bus"

	echo "blacklist i2c-piix4" | tee -a /etc/modprobe.d/blacklist.conf
	update-initramfs -u
}

function changeMotd {

    message "Changing MOTD"

	rm -r /etc/update-motd.d/10-uname
	sed -i "s/#PrintLastLog yes/PrintLastLog no/g" /etc/ssh/sshd_config

cat > /etc/motd <<-"EOF"
       __        ___  _ ______  _       ____         ___ _____
       \ \      / (_)(_)__  (_)(_)_ __ |  _ \  ___  |_ _|_   _|
        \ \ /\ / /| || | / /| || | '_ \| | | |/ _ \  | |  | |
         \ V  V / | || |/ /_| || | | | | |_| |  __/_ | |  | |
          \_/\_/  |_|/ /____|_|/ |_| |_|____/ \___(_)___| |_|
                   |__/      |__/

=======================================================================
                            SECURITY NOTICE
 ---------------------------------------------------------------------
  This is a private secured computer system. It is for authorized use
  only. Users (authorized or unauthorized) have no explicit or
  implicit expectation of privacy. Any or all uses of this system and
  all files on this system may be intercepted, monitored, recorded,
  copied, audited, inspected, and disclosed to authorized site, law
  enforcement personnel, as well as authorized officials of other
  agencies, both domestic and foreign. By using this system, the user
  consents to such interception, monitoring, recording, copying,
  auditing, inspection, and disclosure at the discretion of
  authorized site. All activity is logged with your host name and IP
  address. Unauthorized or improper use of this system may result in
  civil and criminal penalties. By continuing to use this system you
  indicate your awareness of and consent to these terms and conditions
  of use.
 ---------------------------------------------------------------------
 LOG OFF IMMEDIATELY,
   if you do not agree to the conditions stated in this warning.
=======================================================================
EOF
}

main
reboot