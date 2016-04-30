#!/bin/sh
# SE-VPN script
# fetches SE's source code from Github
# builds it
apt-get update -y && apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install -y git dnsmasq bc make gcc openssl build-essential libreadline-dev libncurses5-dev libssl-dev upstart-sysv

git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
cd SoftEtherVPN
cp src/makefiles/linux_64bit.mak Makefile
make
make install
wget -O /etc/init.d/vpnserver https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpnserver.init
chmod +x /etc/init.d/vpnserver
update-rc.d vpnserver defaults

apt-get install iptables-persistent -y
#enatble nat
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

#enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

wget -O /etc/dnsmasq.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/dnsmasq.conf
wget -O /usr/vpnserver/vpn_server.config https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpn_server.config
service dnsmasq restart
service vpnserver start