#!/bin/sh
# SE-VPN script
# fetches SE's source code from Github
# builds it
apt-get update -y && apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install -y git dnsmasq bc make gcc openssl build-essential libreadline-dev libncurses5-dev libssl-dev upstart-sysv

git clone 
cd SoftEtherVPN
cp src/makefiles/linux_64bit.mak Makefile
make
make install
wget -O /etc/init.d/vpnserver 
chmod +x /etc/init.d/vpnserver
update-rc.d vpnserver defaults

apt-get install iptables-persistent -y
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/iptables-vpn.sh
sh iptables-vpn.sh

wget -O /etc/dnsmasq.conf 
wget -O /usr/vpnserver/vpn_server.config 
service dnsmasq restart
service vpnserver start