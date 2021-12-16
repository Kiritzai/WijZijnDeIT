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
	zabbix-agent

	rm /etc/zabbix/zabbix_agentd.conf

echo -e "PidFile=/var/run/zabbix/zabbix_agentd.pid
LogType=system
Server=0.0.0.0/0
ServerActive=127.0.0.1
Hostname=$(hostname)
AllowKey=system.run[*]
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Timeout=30" | tee /etc/zabbix/zabbix_agentd.conf

	systemctl enable zabbix-agent
	systemctl restart zabbix-agent.service

}

main