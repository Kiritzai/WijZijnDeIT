#!/bin/bash

set +H

# Actual Command to Run
# bash <(wget --no-cache -O - https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_Wireguard.sh)
# curl -sSL https://github.com/Kiritzai/WijZijnDeIT/raw/master/Debian_Wireguard.sh | bash


################
## Parameters ##
################

# Software
SOFTWARE="Wireguard"

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


function installUtilities {

	message "Running apt-get update..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' update

	message "Running apt-get upgrade..."
	DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade

	# Declare an array of string with type
	declare -a AppArray=("wireguard" \
							"wireguard-tools" \
							"linux-headers-$(uname -r)" \
							"iptables" \
							"qrencode" \
							"openresolv")


	# Iterate the string array using for loop
	for app in ${AppArray[@]}; do
		message "Installing $app..."
		DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install $app
	done
}
2

function addClient {

	echo
	echo "Provide a name for the client:"
	read -p "Name: " unsanitized_client
	# Allow a limited set of characters to avoid conflicts
	client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
	while [[ -z "$client" ]] || grep -q "^# BEGIN_PEER $client$" /etc/wireguard/wg0.conf; do
		echo "$client: invalid name."
		read -p "Name: " unsanitized_client
		client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
	done

	octet=2
	while grep AllowedIPs /etc/wireguard/wg0.conf | cut -d "." -f 4 | cut -d "/" -f 1 | grep -q "$octet"; do
		(( octet++ ))
	done

	key=$(wg genkey)
	psk=$(wg genpsk)

	read -p $'\tDo you need to route network? (y/n): ' confirm
	case $confirm in 
		[yY] )
			echo
			echo "Provide IP route subnet [ex: 192.168.1.0/24]:"
			read -p "Subnet: " ip_route_subnet
			break
		;;
		[nN] )
			break
		;;
		* )
			echo invalid response
		;;
	esac

	# Append peer
echo -e "# BEGIN_PEER $client
[Peer]
PublicKey = $(wg pubkey <<< $key)
PresharedKey = $psk
AllowedIPs = 10.200.0.$octet/32$([[ -n "$ip_route_subnet" ]] && echo ", $ip_route_subnet")
# END_PEER $client" | tee -a /etc/wireguard/wg0.conf

	# Create client.conf file
echo -e "[Interface]
Address = 10.200.0.$octet/32
DNS = $dns
PrivateKey = $key
[Peer]
PublicKey = $(grep PrivateKey /etc/wireguard/wg0.conf | cut -d " " -f 3 | wg pubkey)
PresharedKey = $psk
AllowedIPs = 10.200.0.0/24$([[ -n "$ip_route_subnet" ]] && echo ", $ip_route_subnet")
Endpoint = vpn.wijzijnde.cloud:$(grep ListenPort /etc/wireguard/wg0.conf | cut -d " " -f 3)
PersistentKeepalive = 25" | tee ~/"$client.conf"

	wg addconf wg0 <(sed -n "/^# BEGIN_PEER $client/,/^# END_PEER $client/p" /etc/wireguard/wg0.conf)
	qrencode -t UTF8 < ~/"$client.conf"
	echo -e '\xE2\x86\x91 That is a QR code containing your client configuration.'
	echo
	echo "$client added. Configuration available in:" ~/"$client.conf"
}



function serverConfig {

	echo "Install Endpoint or Peer"
	echo
	echo "Select an option:"
	echo "   1) Endpoint"
	echo "   2) Peer"
	echo "   3) Exit"
	read -p "Option: " option
	until [[ "$option" =~ ^[1-3]$ ]]; do
		echo "$option: invalid selection."
		read -p "Option: " option
	done

	case "$option" in
			1)
echo -e "# ENDPOINT
[Interface]
Address = 10.200.0.1/24
ListenPort = ${port}
PrivateKey = $(wg genkey)
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
PostUp = echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
PostUp = ip rule add not from 10.200.0.0/24 table main
PostUp = iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostUp = iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostUp = iptables -A FORWARD -i wg0 -o wg0 -m conntrack --ctstate NEW -j ACCEPT
PostDown = ip rule del not from 10.200.0.0/24 table main
PostDown = iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o wg0 -m conntrack --ctstate NEW -j ACCEPT
PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward
PostDown = echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp" | tee /etc/wireguard/wg0.conf
			;;
			2)
			echo
			echo "Enter Interface address of the peer server:"
			read -p $'\tPeer IP: ' peer_ip < /dev/tty

			echo
			echo "Enter local IP of Endpoint server:"
			read -p $'\tEndpoint Local IP: ' endpoint_local_ip < /dev/tty

			echo
			echo "Enter Endpoint public key"
			read -p $'\tEndpoint public key: ' endpoint_public_key < /dev/tty

echo -e "# PEER
[Interface]
Address = ${peer_ip}/32
PrivateKey = $(wg genkey)
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
PostUp = echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens192 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens192 -j MASQUERADE
PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward
PostDown = echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp

[Peer]
PublicKey = ${endpoint_public_key}
AllowedIPs = 10.200.0.1/32, ${endpoint_local_ip}/32
Endpoint = ${endpoint}:${port}
PersistentKeepalive = 25" | tee -a /etc/wireguard/wg0.conf
			;;
			3)
				exit
			;;
	esac

	# Secure file
	sudo chmod 600 /etc/wireguard/ -R

	# Start Wireguard + enable
	systemctl enable wg-quick@wg0.service
	systemctl start wg-quick@wg0.service

	message "Finished!"

}



####
# STARTING PART
####

endpoint="vpn.wijzijnde.cloud"
port="51820"
ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')


function message {
	logdate=$(date "+%d %b %Y %H:%M:%S")
    echo -e "${logdate} :: ${GREEN}#${RESET} $1" #| tee /dev/fd/3
}


# Check if Wireguard if installed
if [[ ! -e /etc/wireguard/wg0.conf ]]; then

	# Summary
	clear
	echo "$BANNER"
cat <<EOF

	Local IP: ${ip}
	Port: ${port}
	Endpoint: ${endpoint}

	Are these settings correct?
 
EOF
	read -p $'\tCorrect? (Y/N): ' confirm && [[ $confirm == [yY] ]] || exit 1
	clear
	echo "$BANNER"

	installUtilities
	serverConfig
else
	clear
	echo "$BANNER"
cat <<EOF

	Wireguard is already installed
 
EOF
	addClient
fi


############################
## Log Settings
############################

# Log file
#logfile="$PWD/log.log"

# Log execute
#exec 3>&1 1>>${logfile} 2>&1

#main
#reboot