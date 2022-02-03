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


function installZabbixProxy {

	# Installing Zabbix Repo
	wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb
	dpkg -i zabbix-release_5.4-1+debian11_all.deb

	# Updating repository
	DEBIAN_FRONTEND=noninteractive apt -yqq update

	DEBIAN_FRONTEND=noninteractive \
	apt -yqq install \
	zabbix-proxy-sqlite3 \
	snmp \
	snmp-mibs-downloader \
	lftp

	rm /etc/zabbix/zabbix_proxy.conf
	find / -type f -name "zabbix.db" -delete

	mkdir /opt/zabbix
	zcat /usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz | sqlite3 /opt/zabbix/zabbix.db
	chmod -R 777 /opt/zabbix
	sudo su beheer -c "echo \"${input_zabbix_psk}\" | tee /home/beheer/zabbix_proxy.psk"

echo -e "Server=zabbix.wijzijnde.it
Hostname=$(hostname)_Zabbix
PidFile=/var/run/zabbix/zabbix_proxy.pid
SocketDir=/var/run/zabbix
LogType=system
DBName=/tmp/zabbix.db
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
TLSPSKFile=/home/beheer/zabbix_proxy.psk" | tee /etc/zabbix/zabbix_proxy.conf

systemctl enable zabbix-proxy
service zabbix-proxy restart
zabbix_proxy -R config_cache_reload




	sed -i "s/^\(mibs *:\).*/#\1/" /etc/snmp/snmp.conf
	#sudo download-mibs

	wget -O /usr/share/snmp/mibs/FROGFOOT-RESOURCES-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FROGFOOT-RESOURCES-MIB.mib
	wget -O /usr/share/snmp/mibs/UBNT-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-MIB
	wget -O /usr/share/snmp/mibs/UBNT-UniFi-MIB.mib http://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB
	wget -O /usr/share/snmp/mibs/FORTINET-FORTIGATE-MIB.mib http://www.circitor.fr/Mibs/Mib/F/FORTINET-FORTIGATE-MIB.mib

	# Download All MIBS from cisco
lftp ftp.cisco.com << EOF
	mirror -c /pub/mibs/v2 /usr/share/snmp/mibs
	bye
EOF

	service zabbix-proxy restart
	zabbix_proxy -R config_cache_reload

}

main