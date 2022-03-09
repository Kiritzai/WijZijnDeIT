#!/bin/bash

set +H

# Actual Command to Run
# bash <(wget --no-cache -O - https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_VPN.sh)
# curl -sSL https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_VPN.sh | bash


################
## Parameters ##
################

# Software
SOFTWARE="VPN"

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


# DHCP Scope
clear
echo "$BANNER"
cat <<EOF

	What DHCP Scope IP should ${SOFTWARE} use?
	Always use 0 [zero] on the last octet.

	Example: 192.168.30.1,192.168.30.250
 
EOF
read -p $'\tScope: ' input_dhcp_scope < /dev/tty


# Gateway
clear
echo "$BANNER"
cat <<EOF

	Enter a gateway IP

	Example: 192.168.30.1
 
EOF
read -p $'\tGateway: ' input_gateway < /dev/tty


# DNS Server
clear
echo "$BANNER"
cat <<EOF

	Enter IP Address for local DNS server
 
EOF
read -p $'\tDNS: ' input_dns_server < /dev/tty


# Domain Name
clear
echo "$BANNER"
cat <<EOF

	Enter FQDN of local domain
	
	Example: domain.lan
 
EOF
read -p $'\tDomain: ' input_domain_name < /dev/tty


# Route
clear
echo "$BANNER"
cat <<EOF

	Enter IP route
	
	Example: [iprange/subnet,gateway]
	Example: 10.10.0.0/16,10.10.10.1

	For multiple routs
	Example: 10.10.0.0/16,10.10.10.1,192.168.30.0/24,10.10.10.1
 
EOF
read -p $'\tRoute: ' input_ip_route < /dev/tty


# Summary
clear
echo "$BANNER"
cat <<EOF

	DHCP Scope: ${input_dhcp_scope}
	DNS Server: ${input_dns_server}
	Domain Name: ${input_domain_name}
	IP Route: ${input_ip_route}
	Gateway: ${input_gateway}

	Are these settings correct?
 
EOF

read -p $'\tCorrect? (Y/N): ' confirm && [[ $confirm == [yY] ]] || exit 1
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
	installVPN
}


function installVPN {

	message "Running apt-get update..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' update

	message "Installing softether-vpnserver..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install softether-vpnserver
	
	message "Installing dnsmasq..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dnsmasq

	echo 'net.ipv4.ip_forward=1' | tee /etc/sysctl.d/ipv4_forwarding.conf
	sysctl --system

	# Backup /etc/dnsmasq.conf
	mv /etc/dnsmasq.conf /etc/dnsmasq.conf-backup

	# Create dnsmasq config
	message "Creating dnsmasq configuration..."

echo -e "##################################################################################
# SoftEther VPN server dnsmasq.conf
################################################################################## Interface Settings

# If you want dnsmasq to listen for DHCP and DNS requests only on
# specified interfaces (and the loopback) give the name of the
# interface (eg eth0) here.
# Repeat the line for more than one interface.
interface=tap_soft

# If you want dnsmasq to really bind only the interfaces it is listening on,
# uncomment this option. About the only time you may need this is when
# running another nameserver on the same machine.
bind-interfaces

################################################################################## Options

# Uncomment this to enable the integrated DHCP server, you need
# to supply the range of addresses available for lease and optionally
# a lease time. If you have more than one network, you will need to
# repeat this for each network on which you want to supply DHCP
# service.
dhcp-range=${input_dhcp_scope},12h

# Override the default route supplied by dnsmasq, which assumes the
# router is the same machine as the one running dnsmasq.
dhcp-option=3

# If you don't want dnsmasq to poll /etc/resolv.conf or other resolv
# files for changes and re-read them then uncomment this.
no-poll

# If you don't want dnsmasq to read /etc/resolv.conf or any other
# file, getting its servers from this file instead (see below), then
# uncomment this.
no-resolv

# Disable re-use of the DHCP servername and filename fields as
# extra option space. This makes extra space available in the
# DHCP packet for options but can, rarely, confuse old or broken
# clients. This flag forces \"simple and safe\" behavior to avoid
# problems in such a case.
dhcp-no-override

# The following directives prevent dnsmasq from forwarding plain names (without any dots)
# or addresses in the non-routed address space to the parent nameservers.
#domain-needed

# Never forward addresses in the non-routed address spaces.
bogus-priv

# Domain
domain=${input_domain_name}

# Set the DHCP server to authoritative mode. In this mode it will barge in
# and take over the lease for any client which broadcasts on the network,
# whether it has a record of the lease or not. This avoids long timeouts
# when a machine wakes up on a new network. DO NOT enable this if there's
# the slighest chance that you might end up accidentally configuring a DHCP
# server for your campus/company accidentally. The ISC server uses
# the same option, and this URL provides more information:
# http://www.isc.org/index.pl?/sw/dhcp/authoritative.php
dhcp-authoritative

################################################################################## External DNS Servers

# Use this DNS servers for incoming DNS requests
server=/${input_domain_name}/${input_dns_server}
server=8.8.8.8
server=8.8.4.4

#########################################

################################################################################## Client DNS Servers

# Let's send these DNS Servers to clients.
# The first IP is the IPv4 address that are already assigned to the tap_soft

# Set IPv4 DNS server for client machines
dhcp-option=option:dns-server,${input_dns_server}

#########################################

################################################################################## Routing

# Let's send these DNS Servers to clients.
# The first IP is the IPv4 address that are already assigned to the tap_soft

# Set IPv4 DNS server for client machines
dhcp-option=option:classless-static-route,${input_ip_route}

#########################################" | tee /etc/dnsmasq.conf

	# Backup /etc/softether-vpnserver.service
	mv /lib/systemd/system/softether-vpnserver.service /lib/systemd/system/softether-vpnserver.service-backup

	# Creating Softether Service
	message "Create service file..."

echo -e "[Unit]
Description=SoftEther VPN Server
After=network-online.target auditd.service

[Service]
Type=forking
TasksMax=629145
EnvironmentFile=-/etc/defaults/softether-vpnserver
ExecStart=/usr/libexec/softether/vpnserver/vpnserver start
ExecStop=/usr/libexec/softether/vpnserver/vpnserver stop
ExecStartPost=/bin/sleep 05
ExecStartPost=/bin/bash /opt/softether-iptables.sh
ExecStartPost=/bin/sleep 03
ExecStartPost=/bin/systemctl start dnsmasq.service
ExecReload=/bin/sleep 05
ExecReload=/bin/bash /root/softether-iptables.sh
ExecReload=/bin/sleep 03
ExecReload=/bin/systemctl restart dnsmasq.service
ExecStopPost=/bin/systemctl stop dnsmasq.service
KillMode=mixed
RestartSec=5s
Restart=on-failure

# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=strict
RuntimeDirectory=softether
StateDirectory=softether
LogsDirectory=softether
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYSLOG CAP_SETUID

[Install]
WantedBy=multi-user.target" | tee /lib/systemd/system/softether-vpnserver.service

	# Grab local IP Address
	local_ip=$(ifconfig $(netstat -rn | grep -E "^default|^0.0.0.0" | head -1 | awk '{print $NF}') | grep 'inet ' | awk '{print $2}' | grep -Eo '([0-9]*\.){3}[0-9]*')

	# Create from gateway an network address
	network=$(IFS=.; set -o noglob; set -- $input_gateway; printf '%s\n' "$1.$2.$3.0")

	# ( To list rules : iptables -t nat -L -n -v )

	message "Create iptables script..."

cat > /opt/softether-iptables.sh <<EOF
#!/bin/bash

# Flush Current rules
iptables -F && iptables -X

#######################################################################################
# Base SoftEther VPN Rules for IPTables
#######################################################################################

# Assign tap_soft to tap interface
/sbin/ifconfig tap_soft ${input_gateway}

iptables -t nat -A POSTROUTING -s ${network}/24 -j SNAT --to-source ${local_ip}

# Allow VPN Interface to access the whole world, back and forth.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -s ${network}/24 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -s ${network}/24 -m state --state NEW -j ACCEPT
iptables -A FORWARD -s ${network}/24 -m state --state NEW -j ACCEPT

#######################################################################################
# End of Base IPTables Rules
#######################################################################################
EOF

	# Make iptables script executable
	chmod +x /opt/softether-iptables.sh

	message "Finished, reboot the server!"

}

main
#reboot