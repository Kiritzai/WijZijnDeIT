#!/bin/bash

set +H

# Actual Command to Run
# bash <(wget --no-cache -O - https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_ZabbixAgent.sh)
# curl -sSL https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_ZabbixAgent.sh | bash


################
## Parameters ##
################

# Software
SOFTWARE="Zabbix Agent"


##################
## Installation ##
##################

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi
clear

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

main () {
	installZabbixAgent
}


function installZabbixAgent {

	# Installing Zabbix Repo
	wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb
	dpkg -i zabbix-release_5.4-1+debian11_all.deb

	# Updating repository
	DEBIAN_FRONTEND=noninteractive apt -yqq update

	DEBIAN_FRONTEND=noninteractive \
	apt -yqq install \
	zabbix-agent \
	snmp \
	snmp-mibs-downloader \
	lftp


	rm /etc/zabbix/zabbix_agentd.conf

echo -e "PidFile=/var/run/zabbix/zabbix_agentd.pid
LogType=system
Server=0.0.0.0/0
ServerActive=127.0.0.1
Hostname=$(hostname)
AllowKey=system.run[*]
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Timeout=30" | tee /etc/zabbix/zabbix_agentd.conf

	





	sed -i "s/^\(mibs *:\).*/#\1/" /etc/snmp/snmp.conf
	#sudo download-mibs

	wget -O /usr/share/snmp/mibs/FROGFOOT-RESOURCES-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FROGFOOT-RESOURCES-MIB.mib
	wget -O /usr/share/snmp/mibs/UBNT-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-MIB
	wget -O /usr/share/snmp/mibs/UBNT-UniFi-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB

	# Download All MIBS from cisco
lftp ftp.cisco.com << EOF
	mirror -c /pub/mibs/v2 /usr/share/snmp/mibs
	bye
EOF

	systemctl enable zabbix-agent
	systemctl restart zabbix-agent.service

	service zabbix-proxy restart
	zabbix_proxy -R config_cache_reload

}

main