#!/bin/sh
# SE-VPN script
# fetches SE's source code from Github
# builds it
apt-get update -y && apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install -y dnsmasq bc make gcc openssl build-essential

wget 
tar xvf softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit.tar.gz
cd vpnserver
make i_read_and_agree_the_license_agreement
1,1,1 (press 1 till finish)
cd ..
mv vpnserver /usr/local/
wget -O /etc/init.d/vpnserver vpnserver.init 
chmod +x /etc/init.d/vpnserver
update-rc.d vpnserver defaults
apt-get install iptables-persistent

#enatble nat
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

#enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

apt-get install dnsmasq -y
wget -O /etc/dnsmasq.conf dnsmasq.conf
/etc/init.d/vpnserver start