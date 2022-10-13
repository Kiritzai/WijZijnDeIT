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

endpoint="vpn.wijzijnde.cloud"
port="51820"
ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')

INSTALLED=0
OPTION_PEER=0
OPTION_ENDPOINT=0

RESET='\033[0m'
YELLOW='\033[1;33m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m'
GREEN='\033[1;32m'


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

# Logging
function message {
	logdate=$(date "+%d %b %Y %H:%M:%S")
    echo -e "${logdate} :: ${GREEN}#${RESET} $1" #| tee /dev/fd/3
}



function main {

	checkInstallation

	[[ $INSTALLED -eq 1 ]] && installWireguard || addClient

	startup

	[[ $OPTION_ENDPOINT -eq 1 ]] && installUtilities
	[[ $OPTION_ENDPOINT -eq 1 ]] && serverConfig

	exit
}

function checkInstallation {
	[[ -e /etc/wireguard/wg0.conf ]] && INSTALLED=1
}

function installWireguard {

	clear
	echo "$BANNER"

	echo 
	echo $'\tInstall Endpoint or Peer'
	echo
	echo $'\tSelect an option:'
	echo $'\t   1) Peer'
	echo $'\t   2) Endpoint'
	echo $'\t   3) Exit'
	echo
	read -p $'\tOption: ' option
	until [[ "$option" =~ ^[1-3]$ ]]; do
		echo "$option: invalid selection."
		read -p $'\tOption: ' option
	done

	case "$option" in
			1)
				[[ $OPTION_PEER -eq 1 ]] && OPTION_PEER=1
				;;
			2)
				[[ $OPTION_ENDPOINT -eq 1 ]] && OPTION_ENDPOINT=1
				;;
			3)
				exit
				;;
	esac

	echo
	echo $'\tLocal IP: ${ip}'
	echo $'\tPort: ${port}'
	echo $'\tEndpoint: ${endpoint}'
	echo
	[[ $OPTION_PEER -eq 1 ]] && echo $'\tChoice: Peer'
	[[ $OPTION_ENDPOINT -eq 1 ]] && echo $'\tChoice: Endpoint'
	echo
	echo $'\tAre these settings correct?'

	read -p $'\tCorrect? (Y/N): ' confirm && [[ $confirm == [yY] ]] || exit 1
	clear
	echo "$BANNER"

}

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

	clear
	echo "$BANNER"
	echo
	echo $'\tWireguard is already installed'

	key=$(wg genkey)
	psk=$(wg genpsk)
	pub=$(wg pubkey <<< $key)

	echo 
	read -p $'\tProvide a name for the client: ' unsanitized_client < /dev/tty
	echo
	read -p $'\tDo you need to route network? (y/n): ' confirm
	case $confirm in 
		[yY] )
			echo
			read -p $'\tProvide IP route subnet [ex: 192.168.1.0/24]: ' ip_route_subnet
		;;
		[nN] )
			break
		;;
		* )
			echo invalid response
		;;
	esac
	echo
	read -p $'\tDo you need to add DNS? (y/n): ' confirm
	case $confirm in 
		[yY] )
			echo
			read -p $'\tProvide DNS server [ex: 192.168.1.31]: ' dns
		;;
		[nN] )
			break
		;;
		* )
			echo invalid response
		;;
	esac

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

	# Append peer
echo -e "
# BEGIN_PEER $client
[Peer]
PublicKey = $pub
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
Endpoint = ${endpoint}:$(grep ListenPort /etc/wireguard/wg0.conf | cut -d " " -f 3)
PersistentKeepalive = 25" | tee ~/"$client.conf"

	wg addconf wg0 <(sed -n "/^# BEGIN_PEER $client/,/^# END_PEER $client/p" /etc/wireguard/wg0.conf)
	qrencode -t UTF8 < ~/"$client.conf"
	echo -e '\xE2\x86\x91 That is a QR code containing your client configuration.'
	echo
	echo "$client added. Configuration available in:" ~/"$client.conf"

	# Restarting Wireguard
	systemctl start wg-quick@wg0.service
}


function addPeer {

	key=$(wg genkey)
	psk=$(wg genpsk)
	pub=$(wg pubkey <<< $key)

	echo 
	read -p $'\tProvide a name for the peer: ' unsanitized_peer < /dev/tty
	echo
	read -p $'\tEnter Interface address of the peer server [ex: 10.200.0.X]: ' peer_ip < /dev/tty
	echo
	read -p $'\tEnter Endpoint public key: ' endpoint_public_key < /dev/tty
	echo
	read -p $'\tDo you need to route network? (y/n): ' confirm
	case $confirm in 
		[yY] )
			echo
			read -p $'\tProvide IP route subnet [ex: 192.168.1.0/24]: ' ip_route_subnet
		;;
		[nN] )
			break
		;;
		* )
			echo invalid response
		;;
	esac

	# Creating peer configuration
echo -e "# PEER
[Interface]
Address = ${peer_ip}/32
PrivateKey = ${key}
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
PostUp = echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens192 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens192 -j MASQUERADE
PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward
PostDown = echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp

[Peer]
PublicKey = ${endpoint_public_key}
PresharedKey = ${psk}
AllowedIPs = 10.200.0.1/24
Endpoint = ${endpoint}:${port}
PersistentKeepalive = 25" | tee /etc/wireguard/wg0.conf

	# Allow a limited set of characters to avoid conflicts
	peer=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_peer")
	while [[ -z "$peer" ]] || grep -q "^# BEGIN_PEER $peer$" /etc/wireguard/wg0.conf; do
		echo "$peer: invalid name."
		read -p "Name: " unsanitized_peer
		peer=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_peer")
	done

	# Create Config
echo -e "# BEGIN_PEER $peer
[Peer]
PublicKey = $pub
PresharedKey = $psk
AllowedIPs = $peer_ip/32$([[ -n "$ip_route_subnet" ]] && echo ", $ip_route_subnet")
# END_PEER $peer" | tee ~/"$peer.conf"

	clear
	echo "$BANNER"
cat <<EOF

	"${peer} added. Configuration available in:" ~/"${peer}.conf"
	Add this to the Endpoint

$(cat ~/"${peer}.conf")

EOF

	# Restarting Wireguard
	systemctl restart wg-quick@wg0.service
}


function serverConfig {

	echo 
	echo $'\tInstall Endpoint or Peer'
	echo
	echo $'\tSelect an option:'
	echo $'\t   1) Endpoint'
	echo $'\t   2) Peer'
	echo $'\t   3) Exit'
	read -p $'\tOption: ' option
	until [[ "$option" =~ ^[1-3]$ ]]; do
		echo "$option: invalid selection."
		read -p $'\tOption: ' option
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
				addPeer
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

main