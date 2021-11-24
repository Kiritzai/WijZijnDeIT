#!/bin/bash

set +H

# Actual Command to Run
# bash <(wget --no-cache -O - https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_OpenVPN.sh)
# curl -sSL https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_OpenVPN.sh | bash


################
## Parameters ##
################

# Software
SOFTWARE="OpenVPN"


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
	
	Example 10.10.10.0 255.255.255.0
 
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
	DEBIAN_FRONTEND=noninteractive apt update

	DEBIAN_FRONTEND=noninteractive \
	apt-get install \
	iptables-persistent \
	softether-vpnserver \
	dnsmasq -yqq

	#echo "interface=tap_soft" | tee -a /etc/dnsmasq.conf
	#echo "dhcp-range=tap_soft,${input_dhcp_scope},12h" | tee -a /etc/dnsmasq.conf
	#echo "dhcp-option=tap_soft,3,${input_gateway}" | tee -a /etc/dnsmasq.conf

	echo 'net.ipv4.ip_forward=1' | tee /etc/sysctl.d/ipv4_forwarding.conf
	sysctl --system

	# Backup /etc/dnsmasq.conf
	mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

	

echo -e "
##################################################################################
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
dhcp-option=3,${input_gateway}

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

# Never forward addresses in the non-routed address spaces.
bogus-priv

################################################################################## External DNS Servers

# Use this DNS servers for incoming DNS requests = Cloudflare
server=8.8.8.8
server=8.8.4.4

#########################################

################################################################################## Client DNS Servers

# Let's send these DNS Servers to clients.
# The first IP is the IPv4 address that are already assigned to the tap_soft

# Set IPv4 DNS server for client machines
dhcp-option=option:dns-server,${input_dns_server}

#########################################" | tee /etc/dnsmasq.conf


echo -e "
#!/bin/sh
### BEGIN INIT INFO
# Provides:          vpnserver
# Required-Start:    \$network \$remote_fs
# Required-Stop:     \$network \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SoftEther VPN Server
### END INIT INFO

DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
TAP_ADDR=${input_gateway}
TAP_INTERFACE=tap_soft

test -x \$DAEMON || exit 0
case "\$1" in
start)
\$DAEMON start
touch \$LOCK
sleep 3
#####################################################
#       ifconfig tap interface                      
#####################################################
#
# Assign \$TAP_ADDR to our tap interface
/sbin/ifconfig \$TAP_INTERFACE \$TAP_ADDR
#
#####################################################
#       End                                         
#####################################################
sleep 3
service dnsmasq start
;;
stop)
\$DAEMON stop
rm \$LOCK
;;
restart)
\$DAEMON stop
sleep 3
\$DAEMON start
sleep 3
######################################################
#       ifconfig tap interface                       
######################################################
#
# Assign \$TAP_ADDR to our tap interface
/sbin/ifconfig \$TAP_INTERFACE \$TAP_ADDR
#
######################################################
#       End                                          
######################################################
sleep 3
service dnsmasq restart
;;
*)
echo \"Usage: \$0 {start|stop|restart}\"
exit 1
esac
exit 0" | tee /etc/init.d/vpnserver

	chmod +x /etc/init.d/vpnserver

	local_ip=$(ip addr | grep inet | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
	network=$(IFS=.; set -o noglob; set -- $input_gateway; printf '%s\n' "$1.$2.$3.0")

    iptables -t nat -A POSTROUTING -s $network/24 -j SNAT --to-source $local_ip

	/etc/init.d/vpnserver restart
	/etc/init.d/dnsmasq restart


#echo "[Unit]
#Before=network.target
#[Service]
#Type=oneshot
#ExecStart=/sbin/iptables -t nat -A POSTROUTING -s $input_dhcp_scope/24 ! -d $input_dhcp_scope/24 -j SNAT --to $ip
#ExecStart=/sbin/iptables -I INPUT -p udp --dport 1194 -j ACCEPT
#ExecStart=/sbin/iptables -I FORWARD -s $input_dhcp_scope/24 -j ACCEPT
#ExecStart=/sbin/iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
#ExecStop=/sbin/iptables -t nat -D POSTROUTING -s $input_dhcp_scope/24 ! -d $input_dhcp_scope/24 -j SNAT --to $ip
#ExecStop=/sbin/iptables -D INPUT -p udp --dport 1194 -j ACCEPT
#ExecStop=/sbin/iptables -D FORWARD -s $input_dhcp_scope/24 -j ACCEPT
#ExecStop=/sbin/iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
#RemainAfterExit=yes
#[Install]
#WantedBy=multi-user.target" | tee /etc/systemd/system/openvpn-iptables.service


	# Import the public GPG key
	#wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add -

	# Create OpenVPN repo list
	#echo "deb http://build.openvpn.net/debian/openvpn/stable bullseye main" > /etc/apt/sources.list.d/openvpn-aptrepo.list

	

}

main
#reboot