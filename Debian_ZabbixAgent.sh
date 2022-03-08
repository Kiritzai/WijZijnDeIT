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

RESET='\033[0m'
YELLOW='\033[1;33m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

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

clear
echo "$BANNER"

############################
## Log Settings
############################

# Log file
logfile="$PWD/log.log"

# Log execute
exec 3>&1 1>>${logfile} 2>&1

function message {
	logdate=$(date "+%d %b %Y %H:%M:%S")
    echo -e "${logdate} :: ${GREEN}#${RESET} $1" | tee /dev/fd/3
}

main () {
	installZabbixAgent
}

function installZabbixAgent {

	message "Running apt-get clean..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' clean

	# Installing Zabbix Repo
	wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-1+debian$(cut -d"." -f1 /etc/debian_version)_all.deb
	dpkg -i zabbix-release_6.0-1+debian$(cut -d"." -f1 /etc/debian_version)_all.deb

	message "Running apt-get update..."
	DEBIAN_FRONTEND=noninteractive apt -yqq update
	
	message "Running apt-get upgrade..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade

	message "Running apt-get autoremove..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' autoremove

	#message "Fix broken packages..."
	#dpkg --configure -a
	#DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken

	message "Installing zabbix-agent..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install zabbix-agent

	rm /etc/zabbix/zabbix_agentd.conf

	message "Creating config file..."

cat > /etc/zabbix/zabbix_agentd.conf <<EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogType=system
Server=0.0.0.0/0
ServerActive=127.0.0.1
Hostname=$(hostname)
AllowKey=system.run[*]
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Timeout=30
EOF

	message "Enable zabbix-agent..."
	systemctl enable zabbix-agent
	systemctl restart zabbix-agent.service

	message "Finished installing ${SOFTWARE}..."

}

main