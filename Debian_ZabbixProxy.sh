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


main () {
	clear
	echo "$BANNER"
	installZabbixProxy
}


function installZabbixProxy {

	# Installing Zabbix Repo
	wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb 2> /dev/null
	dpkg -i zabbix-release_5.4-1+debian11_all.deb 2> /dev/null

	# Updating repository
	echo -e "${GREEN}#${RESET} Running apt-get update..."
	DEBIAN_FRONTEND=noninteractive apt -yqq update 2> /dev/null
	
	echo -e "${GREEN}#${RESET} Running apt-get upgrade..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade 2> /dev/null

	echo -e "${GREEN}#${RESET} Fix broken packages..."
	dpkg --configure -a
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken

	echo -e "${GREEN}#${RESET} Installing zabbix-proxy-sqlite3..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install zabbix-proxy-sqlite3 2> /dev/null

	echo -e "${GREEN}#${RESET} Installing snmp..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install snmp 2> /dev/null

	echo -e "${GREEN}#${RESET} Installing snmp-mibs-downloader..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install snmp-mibs-downloader 2> /dev/null

	echo -e "${GREEN}#${RESET} Installing lftp..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lftp 2> /dev/null

	echo -e "${GREEN}#${RESET} Removing zabbix proxy residue..."
	rm /etc/zabbix/zabbix_proxy.conf 2> /dev/null
	find / -type f -name "zabbix.db" -delete 2> /dev/null

	echo -e "${GREEN}#${RESET} Creating SQLite database..."
	mkdir /opt/zabbix 2> /dev/null
	zcat /usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz | sqlite3 /opt/zabbix/zabbix.db 2> /dev/null
	chmod -R 777 /opt/zabbix 2> /dev/null

	echo -e "${GREEN}#${RESET} Create PSK file..."
	echo "${input_zabbix_psk}" | tee /opt/zabbix/zabbix_proxy.psk 2> /dev/null

	echo -e "${GREEN}#${RESET} Create config file..."
echo -e "Server=zabbix.wijzijnde.it
Hostname=$(hostname)_Zabbix
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
StartPollersUnreachable=10
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
TLSPSKFile=/opt/zabbix/zabbix_proxy.psk" | tee /etc/zabbix/zabbix_proxy.conf 2> /dev/null

	echo -e "${GREEN}#${RESET} Enable SNMP..."
	sed -i "s/^\(mibs *:\).*/#\1/" /etc/snmp/snmp.conf 2> /dev/null

	echo -e "${GREEN}#${RESET} Downloading SNMP MIBS..."
	download-mibs 2> /dev/null

	wget -O /usr/share/snmp/mibs/FROGFOOT-RESOURCES-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FROGFOOT-RESOURCES-MIB.mib 2> /dev/null
	wget -O /usr/share/snmp/mibs/UBNT-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-MIB 2> /dev/null
	wget -O /usr/share/snmp/mibs/UBNT-UniFi-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB 2> /dev/null
	wget -O /usr/share/snmp/mibs/FORTINET-FORTIGATE-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FORTINET-FORTIGATE-MIB.mib 2> /dev/null

	# Download All MIBS from cisco
#lftp ftp.cisco.com << EOF
	#mirror -c /pub/mibs/v2 /usr/share/snmp/mibs
	#bye
#EOF

	systemctl enable zabbix-proxy 2> /dev/null
	service zabbix-proxy restart 2> /dev/null
	zabbix_proxy -R config_cache_reload 2> /dev/null

}

main