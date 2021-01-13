#!/bin/bash

# curl -sSL https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Debian_ZabbixProxy_Upgrade.sh | bash
# curl -sSL http://install.wijzijnde.it | bash
# bash <(wget -O - http://install.wijzijnde.it)
# bash <(wget -O - https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Debian_ZabbixProxy_Upgrade.sh)

############################
#
## Installation
#
############################



if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi
clear


main () {
	installZabbixRepo
	changeSources
	disableWrites
	exit
}

function changeSources {
	apt clean
	rm /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ stable contrib main non-free" | tee /etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ stable contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb http://security.debian.org/debian-security stable/updates contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb-src http://security.debian.org/debian-security stable/updates contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ stable-updates contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ stable-updates contrib main non-free" | tee -a /etc/apt/sources.list
	apt update
	apt install --reinstall dpkg libc-bin -yq
	apt update
	apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
	apt autoremove -yq
}

function disableWrites {
	echo "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0" |tee -a /etc/fstab
	echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=500m 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/run tmpfs defaults,noatime,nosuid,mode=0755,size=200m 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/spool/mqueue tmpfs defaults,noatime,nosuid,mode=0700,gid=12,size=300m 0 0" | tee -a /etc/fstab
}

function installZabbixRepo {
	rm -rf /etc/apt/sources.list.d/zabbix.list
	wget https://repo.zabbix.com/zabbix/5.2/debian/pool/main/z/zabbix-release/zabbix-release_5.2-1+debian10_all.deb
	dpkg -i --force-all -B zabbix-release_5.2-1+debian10_all.deb
	rm -rf zabbix-release_5.2-1+debian10_all.deb
	apt update
}

main
reboot