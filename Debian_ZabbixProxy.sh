#!/bin/bash

set +H

# Actual Command to Run
# bash <(wget --no-cache -O - https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_ZabbixProxy.sh)
# curl -sSL https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_ZabbixProxy.sh | bash


################
## Parameters ##
################

# Software
SOFTWARE="Zabbix Proxy"

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
	echo -e "${RED}# Sorry, you need to run this as root"
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


# Input Zabbix PSK
clear
echo "$BANNER"
cat <<EOF

	Enter Zabbix Proxy PSK key
 
EOF
read -p $'\tPSK: ' input_zabbix_psk < /dev/tty

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
	installZabbixProxy
}


function installZabbixProxy {

	# Stopping any running zabbix services
	message "Stopping any running zabbix services..."
	for zabbixService in $(systemctl --type=service --state=running | awk '/zabbix/ {print $1}')
	do
		systemctl kill $zabbixService
		systemctl stop $zabbixService
	done

	# Installing Zabbix Repo
	message "Installing Zabbix Repo..."
	find / -type f -name "zabbix.db" -delete
	find / -type f -name "zabbix*.list" -delete
	wget https://repo.zabbix.com/zabbix/6.2/debian/pool/main/z/zabbix-release/zabbix-release_6.2-1+debian11_all.deb
	dpkg -i zabbix-release_6.2-1+debian11_all.deb

	# Updating repository
	message "Running apt-get update..."
	DEBIAN_FRONTEND=noninteractive apt -yqq update
	
	message "Running apt-get upgrade..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade

	message "Running apt-get dist-upgrade..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade

	message "Installing zabbix-sql-scripts..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install zabbix-sql-scripts

	message "Installing zabbix-proxy-sqlite3..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install zabbix-proxy-sqlite3

	message "Installing zabbix-agent..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install zabbix-agent

	message "Installing snmp..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install snmp

	message "Installing snmp-mibs-downloader..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install snmp-mibs-downloader

	message "Installing lftp..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lftp

	message "Removing zabbix proxy residue..."
	rm -rf /opt/zabbix
	rm /etc/zabbix/zabbix_proxy.conf
	find / -type f -name "zabbix.db" -delete

	message "Creating SQLite database..."
	mkdir /opt/zabbix
	cat /usr/share/doc/zabbix-sql-scripts/sqlite3/proxy.sql | sqlite3 /opt/zabbix/zabbix.db
	chmod -R 777 /opt/zabbix

	message "Create PSK file..."
	echo "${input_zabbix_psk}" | tee /opt/zabbix/zabbix_proxy.psk

	message "Create config file..."
echo -e "Server=zabbix.wijzijnde.it
Hostname=$(hostname)
PidFile=/var/run/zabbix/zabbix_proxy.pid
SocketDir=/var/run/zabbix
LogType=system
DBName=/opt/zabbix/zabbix.db
DBUser=zabbix
SNMPTrapperFile=/var/log/snmptrap.log
Timeout=30
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/bin/fping
Fping6Location=/usr/bin/fping6
EnableRemoteCommands=1
LogSlowQueries=3000
CacheSize=50M
StartPingers=4
StartPollers=10
StartPollersUnreachable=4
StatsAllowedIP=0.0.0.0/0
StartIPMIPollers=1
StartDiscoverers=5
StartVMwareCollectors=1
StartHTTPPollers=2
HistoryCacheSize=50M
HistoryIndexCacheSize=25M
DataSenderFrequency=10
ProxyOfflineBuffer=6
TLSConnect=psk
TLSPSKIdentity=ZabbixPSK
TLSPSKFile=/opt/zabbix/zabbix_proxy.psk" | tee /etc/zabbix/zabbix_proxy.conf

	message "Enable SNMP..."
	sed -i "s/^\(mibs *:\).*/#\1/" /etc/snmp/snmp.conf

	message "Downloading SNMP MIBS..."
	download-mibs

	wget -O /usr/share/snmp/mibs/FROGFOOT-RESOURCES-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FROGFOOT-RESOURCES-MIB.mib
	wget -O /usr/share/snmp/mibs/UBNT-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-MIB
	wget -O /usr/share/snmp/mibs/UBNT-UniFi-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB
	wget -O /usr/share/snmp/mibs/FORTINET-FORTIGATE-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FORTINET-FORTIGATE-MIB.mib

	# Download All MIBS from cisco
#lftp ftp.cisco.com << EOF
	#mirror -c /pub/mibs/v2 /usr/share/snmp/mibs
	#bye
#EOF

	message "Restarting zabbix proxy..."
	systemctl enable zabbix-proxy
	service zabbix-proxy restart
	zabbix_proxy -R config_cache_reload

	message "Create agent config..."
echo -e "PidFile=/var/run/zabbix/zabbix_agentd.pid
LogType=system
Server=0.0.0.0/0
ServerActive=127.0.0.1
Hostname=$(hostname)
AllowKey=system.run[*]
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Timeout=30" | tee /etc/zabbix/zabbix_agentd.conf

	message "Restarting zabbix agent..."
	systemctl enable zabbix-agent
	systemctl restart zabbix-agent.service

	message "Finished"

}

main