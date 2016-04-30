#!/bin/sh
# SE-VPN script
# fetches SE's source code from Github
# builds it
apt-get update -y && apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install -y git dnsmasq bc make gcc openssl build-essential libreadline-dev libncurses5-dev libssl-dev upstart-sysv
apt-get install -y unzip

git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
cd SoftEtherVPN
cp src/makefiles/linux_64bit.mak Makefile
make
make install
wget -O /etc/init.d/vpnserver https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpnserver.init
chmod +x /etc/init.d/vpnserver
update-rc.d vpnserver defaults

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

apt-get install iptables-persistent -y
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/iptables-vpn.sh
sh iptables-vpn.sh

wget -O /etc/dnsmasq.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/dnsmasq.conf
wget -O /usr/vpnserver/vpn_server.config https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpn_server.config
service dnsmasq restart
service vpnserver start
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/scrunge.sh
chmod +x scrunge.sh

echo "Enter a host name for this server"
vpncmd 127.0.0.1:5555 /SERVER /CMD:DynamicDnsSetHostname 
service vpnserver restart
echo "Go to the this url to get your OpenVPN config file"
vpncmd 127.0.0.1:5555 /SERVER /CMD:OpenVpnMakeConfig openvpn
unzip openvpn.zip
sed -i '/^\s*[@#]/ d' *.ovpn
sed -i '/^\s*$/d' *.ovpn
cat *_remote*.ovpn | ./scrunge.sh

vpncmd 127.0.0.1:5555 /SERVER /CMD:ServerPasswordSet