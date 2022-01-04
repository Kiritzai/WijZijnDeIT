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

	What DHCP Scope IP should OpenVPN use?
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

	Are these your settings?
 
EOF

read -p $'\tCorrect? (Y/N): ' confirm && [[ $confirm == [yY] ]] || exit 1

main () {
	installVPN
}


function installVPN {

	# Updating repository
	DEBIAN_FRONTEND=noninteractive apt -yqq update

	DEBIAN_FRONTEND=noninteractive \
	apt-get -yqq install \
	iptables-persistent \
	softether-vpnserver \
	dnsmasq

	#echo "interface=tap_soft" | tee -a /etc/dnsmasq.conf
	#echo "dhcp-range=tap_soft,${input_dhcp_scope},12h" | tee -a /etc/dnsmasq.conf
	#echo "dhcp-option=tap_soft,3,${input_gateway}" | tee -a /etc/dnsmasq.conf

	echo 'net.ipv4.ip_forward=1' | tee /etc/sysctl.d/ipv4_forwarding.conf
	sysctl --system

	# Backup /etc/dnsmasq.conf
	mv /etc/dnsmasq.conf /etc/dnsmasq.conf-backup

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

 Set the DHCP server to authoritative mode. In this mode it will barge in
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


	# Backup /etc/dnsmasq.conf
	mv /lib/systemd/system/softether-vpnserver.service /lib/systemd/system/softether-vpnserver.service-backup

echo -e "[Unit]
Description=SoftEther VPN Server
After=network-online.target auditd.service
Wants=network-online.target

[Service]
Type=forking
TasksMax=629145
EnvironmentFile=-/etc/defaults/softether-vpnserver
ExecStart=/usr/libexec/softether/vpnserver/vpnserver start
ExecStop=/usr/libexec/softether/vpnserver/vpnserver stop
ExecStartPost=sleep 3
ExecStartPost=/usr/sbin/ifconfig tap_soft ${$input_gateway}
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

	# Depends on SoftEther vpnserver
	sed -i "s/After=network.target/After=softether-vpnserver.service network.target/g" /lib/systemd/system/dnsmasq.service

	# Let tap_soft interface be created before starting
	sed -i '/Test the config file and refuse starting if it is not valid/a ExecStartPre=/\bin/\sleep 3' /lib/systemd/system/dnsmasq.service

	# Grab local IP Address
	local_ip=$(ip addr | grep inet | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

	# Create from gateway an network address
	network=$(IFS=.; set -o noglob; set -- $input_gateway; printf '%s\n' "$1.$2.$3.0")

	# make iptables ( To list rules : iptables -t nat -L -n -v )
    iptables -t nat -A POSTROUTING -s $network/24 -j SNAT --to-source $local_ip
	iptables -I INPUT -p udp --dport 5555 -j ACCEPT
	iptables -I FORWARD -s $network/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

}

main
reboot