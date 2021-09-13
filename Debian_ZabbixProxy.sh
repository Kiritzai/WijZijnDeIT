#!/bin/bash

# curl -sSL http://10.30.36.3/Debian_ZabbixProxy.sh | bash
# curl -sSL https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Debian_ZabbixProxy.sh | bash
# curl -sSL http://install.wijzijnde.it | bash
# bash <(wget -O - http://install.wijzijnde.it)

############################
#
## Installation
#
############################



if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

clear
echo
echo "####################################"
echo "##"
echo "## Do you want to install Zabbix Proxy?"
echo "##"
echo "## 1 = YES"
echo "##"
echo "####################################"
echo
read zabbixInstall < /dev/tty
if [ -z $zabbixInstall ]; then
	# Zabbix Proxy will not install by default
	zabbixInstall=0
fi

clear
echo
echo "####################################"
echo "##"
echo "## Do you want to install OpenVPN?"
echo "##"
echo "## 1 = YES"
echo "##"
echo "####################################"
echo
read openvpnInstall < /dev/tty
if [ -z $openvpnInstall ]; then
	# OpenVPN will not install by default
	openvpnInstall=0
fi

if [ $zabbixInstall -eq 1 ]; then
	clear
	echo
	echo "####################################"
	echo "##"
	echo "## Enter Zabbix PSK Proxy"
	echo "##"
	echo "####################################"
	echo
	read input_zabbix_psk < /dev/tty
fi

if [ $openvpnInstall -eq 1 ]; then
	clear
	echo
	echo "###################################"
	echo "##"
	echo "## What OpenVPN IP Address do you want to use?"
	echo "## Always end with a 0 'zero'"
	echo "##"
	echo "## Example [10.20.30.0]"
	echo "##"
	echo "###################################"
	echo
	read input_ipaddress < /dev/tty

	clear
	echo
	echo "###################################"
	echo "##"
	echo "## What OpenVPN WAN IP Address do you want to use?"
	echo "##"
	echo "###################################"
	echo
	read input_public_ip < /dev/tty

	clear
	echo
	echo "###################################"
	echo "##"
	echo "## Enter IP Address of an DNS Server on location"
	echo "##"
	echo "###################################"
	echo
	read input_dns_server < /dev/tty

	clear
	echo
	echo "###################################"
	echo "##"
	echo "## Enter FQDN of the location; example [domain.lan]"
	echo "##"
	echo "###################################"
	echo
	read input_domain_name < /dev/tty

	clear
	echo
	echo "###################################"
	echo "##"
	echo "## Enter IP route"
	echo "##"
	echo "## Example [10.10.10.0 255.255.255.0]"
	echo "##"
	echo "###################################"
	echo
	read input_ip_route < /dev/tty
fi


main () {
	changeSources
	installUtilities
	changeGrub
	setSudo
	changeMotd
	disableWrites
	smBusFix
	if [ $zabbixInstall -eq 1 ]; then
		installZabbixRepo
		installZabbixAgent
		installZabbixProxy
	fi
	if [ $openvpnInstall -eq 1 ]; then
		installOpenVPN
	fi
	exit
}

function changeSources {
	DEBIAN_FRONTEND=noninteractive apt clean
	rm /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ stable contrib main non-free" | tee /etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ stable contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb http://security.debian.org/debian-security stable-security contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb-src http://security.debian.org/debian-security stable-security contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ stable-updates contrib main non-free" | tee -a /etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ stable-updates contrib main non-free" | tee -a /etc/apt/sources.list
	#echo "deb http://deb.debian.org/debian stable-backports main" > /etc/apt/sources.list.d/backports.list
	DEBIAN_FRONTEND=noninteractive apt update
	DEBIAN_FRONTEND=noninteractive apt install --reinstall dpkg libc-bin -yqq
	DEBIAN_FRONTEND=noninteractive apt update
	DEBIAN_FRONTEND=noninteractive apt upgrade -yqq
	DEBIAN_FRONTEND=noninteractive apt autoremove -yqq
}

function installUtilities {
	apt install mlocate open-vm-tools sudo curl -yq
}

function changeGrub {
	sed -i 's/GRUB_TIMEOUT=./GRUB_TIMEOUT=0/g' /etc/default/grub
	#sed -i 's/GRUB_CMDLINE_LINUX=""./GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
	update-grub
}

function setSudo {
	echo "beheer    ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/010_beheer-nopasswd
}

function changeMotd {
	rm -r /etc/update-motd.d/10-uname
	sed -i "s/#PrintLastLog yes/PrintLastLog no/g" /etc/ssh/sshd_config

cat > /etc/motd <<-"EOF"
       __        ___  _ ______  _       ____         ___ _____
       \ \      / (_)(_)__  (_)(_)_ __ |  _ \  ___  |_ _|_   _|
        \ \ /\ / /| || | / /| || | '_ \| | | |/ _ \  | |  | |
         \ V  V / | || |/ /_| || | | | | |_| |  __/_ | |  | |
          \_/\_/  |_|/ /____|_|/ |_| |_|____/ \___(_)___| |_|
                   |__/      |__/
=======================================================================
                            SECURITY NOTICE
 ---------------------------------------------------------------------
  This is a private secured computer system. It is for authorized use
  only. Users (authorized or unauthorized) have no explicit or
  implicit expectation of privacy. Any or all uses of this system and
  all files on this system may be intercepted, monitored, recorded,
  copied, audited, inspected, and disclosed to authorized site, law
  enforcement personnel, as well as authorized officials of other
  agencies, both domestic and foreign. By using this system, the user
  consents to such interception, monitoring, recording, copying,
  auditing, inspection, and disclosure at the discretion of
  authorized site. All activity is logged with your host name and IP
  address. Unauthorized or improper use of this system may result in
  civil and criminal penalties. By continuing to use this system you
  indicate your awareness of and consent to these terms and conditions
  of use.
 ---------------------------------------------------------------------
 LOG OFF IMMEDIATELY,
   if you do not agree to the conditions stated in this warning.
=======================================================================
EOF
}

function disableWrites {

	if grep -iRlq "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" /etc/fstab; then
		number=$(grep -iRn "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" /etc/fstab | cut -d: -f1)
		sed -i "$number,\$d" /etc/fstab
	fi

	echo "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=500M 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0" |tee -a /etc/fstab
	echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=500m 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/run tmpfs defaults,noatime,nosuid,mode=0755,size=200m 0 0" | tee -a /etc/fstab
	echo "tmpfs /var/spool/mqueue tmpfs defaults,noatime,nosuid,mode=0700,gid=12,size=300m 0 0" | tee -a /etc/fstab
}

function smBusFix {
	echo "blacklist i2c-piix4" | tee -a /etc/modprobe.d/blacklist.conf
	update-initramfs -u
}

function installZabbixRepo {
	wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb
	dpkg -i zabbix-release_5.4-1+debian11_all.deb
	DEBIAN_FRONTEND=noninteractive apt update
}

function installZabbixAgent {
	apt install zabbix-agent -yq
	rm /etc/zabbix/zabbix_agentd.conf

	echo "PidFile=/var/run/zabbix/zabbix_agentd.pid" | sudo tee /etc/zabbix/zabbix_agentd.conf
	echo "LogType=system" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	echo "Server=0.0.0.0/0" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	echo "ServerActive=127.0.0.1" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	echo "Hostname=$(hostname)" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	echo "AllowKey=system.run[*]" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	echo "Include=/etc/zabbix/zabbix_agentd.d/*.conf" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	echo "Timeout=30" | sudo tee -a /etc/zabbix/zabbix_agentd.conf

	systemctl enable zabbix-agent
	systemctl restart zabbix-agent.service
}

function installZabbixProxy {
	apt install zabbix-proxy-sqlite3 -yq
	mkdir /opt/zabbix
	zcat /usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz | sqlite3 /opt/zabbix/zabbix.db
	chmod -R 777 /opt/zabbix
	sudo su beheer -c "echo \"${input_zabbix_psk}\" | tee /home/beheer/zabbix_proxy.psk"
	AgentName=$(hostname)_Zabbix
	echo "Server=zabbix.wijzijnde.it" | tee /etc/zabbix/zabbix_proxy.conf
	echo "Hostname=${AgentName}" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "PidFile=/var/run/zabbix/zabbix_proxy.pid" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "SocketDir=/var/run/zabbix" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "LogType=system" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "DBName=/tmp/zabbix.db" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "DBUser=zabbix" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "SNMPTrapperFile=/var/log/snmptrap.log" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "Timeout=30" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "ExternalScripts=/usr/lib/zabbix/externalscripts" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "FpingLocation=/usr/bin/fping" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "Fping6Location=/usr/bin/fping6" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "EnableRemoteCommands=1" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "LogSlowQueries=3000" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "CacheSize=8M" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartPingers=1" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartPollers=10" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartPollersUnreachable=1" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StatsAllowedIP=0.0.0.0/0" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartIPMIPollers=1" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartDiscoverers=3" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartVMwareCollectors=1" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "StartHTTPPollers=1" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "HistoryCacheSize=16M" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "HistoryIndexCacheSize=4M" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "DataSenderFrequency=10" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "ProxyOfflineBuffer=168" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "TLSConnect=psk" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "TLSPSKIdentity=ZabbixPSK" | tee -a /etc/zabbix/zabbix_proxy.conf
	echo "TLSPSKFile=/home/beheer/zabbix_proxy.psk" | tee -a /etc/zabbix/zabbix_proxy.conf
	systemctl enable zabbix-proxy
}

function installOpenVPN {
	ip=$(ip addr | grep inet | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
	apt install openvpn iptables openssl ca-certificates -yq
	easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz'
	wget -O ~/easyrsa.tgz "$easy_rsa_url" 2>/dev/null || curl -Lo ~/easyrsa.tgz "$easy_rsa_url"
	tar xzf ~/easyrsa.tgz -C ~/
	mv ~/EasyRSA-v3.0.6/ /etc/openvpn/server/
	mv /etc/openvpn/server/EasyRSA-v3.0.6/ /etc/openvpn/server/easy-rsa/
	chown -R root:root /etc/openvpn/server/easy-rsa/
	rm -f ~/easyrsa.tgz
	cd /etc/openvpn/server/easy-rsa/
	#dd if=/dev/urandom of=/etc/openvpn/server/easy-rsa/pki/.rnd bs=256 count=1
	bash /etc/openvpn/server/easy-rsa/easyrsa init-pki
	dd if=/dev/urandom of=/etc/openvpn/server/easy-rsa/pki/.rnd bs=256 count=1
	bash /etc/openvpn/server/easy-rsa/easyrsa --batch build-ca nopass
	EASYRSA_CERT_EXPIRE=3650
	bash /etc/openvpn/server/easy-rsa/easyrsa build-server-full server nopass
	EASYRSA_CERT_EXPIRE=3650
	bash /etc/openvpn/server/easy-rsa/easyrsa build-client-full "$(hostname)" nopass
	EASYRSA_CRL_DAYS=3650
	bash /etc/openvpn/server/easy-rsa/easyrsa gen-crl
	cp pki/ca.crt pki/private/ca.key pki/issued/server.crt pki/private/server.key pki/crl.pem /etc/openvpn/server
	chown nobody:nogroup /etc/openvpn/server/crl.pem
	openvpn --genkey --secret /etc/openvpn/server/tc.key
	echo '-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----' | tee /etc/openvpn/server/dh.pem
	# Generating server.conf
	echo "port 1194
proto udp
dev tun
sndbuf 0
rcvbuf 0
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-crypt tc.key
topology subnet
server $input_ipaddress 255.255.255.0
ifconfig-pool-persist ipp.txt
push \"dhcp-option DOMAIN $input_domain_name\"
push \"dhcp-option DNS $input_dns_server\"
push \"ignore redirect-gateway\"
push \"route $input_ip_route\"
push \"route-metric 9000\"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify crl.pem
explicit-exit-notify
client-to-client
duplicate-cn" | tee /etc/openvpn/server/server.conf
	echo 'net.ipv4.ip_forward=1' | tee /etc/sysctl.d/30-openvpn-forward.conf
	echo "[Unit]
Before=network.target
[Service]
Type=oneshot
ExecStart=/sbin/iptables -t nat -A POSTROUTING -s $input_ipaddress/24 ! -d $input_ipaddress/24 -j SNAT --to $ip
ExecStart=/sbin/iptables -I INPUT -p udp --dport 1194 -j ACCEPT
ExecStart=/sbin/iptables -I FORWARD -s $input_ipaddress/24 -j ACCEPT
ExecStart=/sbin/iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=/sbin/iptables -t nat -D POSTROUTING -s $input_ipaddress/24 ! -d $input_ipaddress/24 -j SNAT --to $ip
ExecStop=/sbin/iptables -D INPUT -p udp --dport 1194 -j ACCEPT
ExecStop=/sbin/iptables -D FORWARD -s $input_ipaddress/24 -j ACCEPT
ExecStop=/sbin/iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" | tee /etc/systemd/system/openvpn-iptables.service
	systemctl enable --now openvpn-iptables.service
	echo "client
dev tun
float
pull
proto udp
sndbuf 0
rcvbuf 0
remote $input_public_ip 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
key-direction 1
auth-nocache
verb 3" | tee /etc/openvpn/server/client-common.txt
	systemctl enable --now openvpn-server@server.service
	sudo su beheer -c "cat /etc/openvpn/server/client-common.txt | tee /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"<ca>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "sudo cat /etc/openvpn/server/easy-rsa/pki/ca.crt | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"</ca>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"<cert>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "sudo sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/easy-rsa/pki/issued/$(hostname).crt | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"</cert>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"<key>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "sudo cat /etc/openvpn/server/easy-rsa/pki/private/$(hostname).key | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"</key>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"<tls-crypt>\" | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "sudo sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key | tee -a /home/beheer/$(hostname).ovpn"
	sudo su beheer -c "echo \"</tls-crypt>\" | tee -a /home/beheer/$(hostname).ovpn"
}

main
reboot