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

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

apt-get install iptables-persistent -y
wget 
sh iptables-vpn.sh

wget -O /etc/dnsmasq.conf  
wget -O /usr/vpnserver/vpn_server.config 
service dnsmasq restart
service vpnserver start