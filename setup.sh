#!/bin/sh
# SE-VPN script
# fetches SE's source code from Github
# builds it
apt-get update -y && apt-get upgrade -y
apt-get dist-upgrade -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get install -y unzip curl git dnsmasq bc make gcc openssl build-essential libreadline-dev libncurses5-dev libssl-dev upstart-sysv iptables-persistent

git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
cd SoftEtherVPN
cp src/makefiles/linux_64bit.mak Makefile
make
make install
cd ..
wget -O /etc/init.d/vpnserver https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpnserver.init
chmod +x /etc/init.d/vpnserver
update-rc.d vpnserver defaults

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/iptables-vpn.sh
sh iptables-vpn.sh

wget -O /etc/dnsmasq.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/dnsmasq.conf
wget -O /usr/vpnserver/vpn_server.config https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpn_server.config
service dnsmasq restart
service vpnserver start
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/scrunge.sh
chmod +x scrunge.sh
FILE=/usr/share/dict/american-english
WORD=$(sort -R $FILE | head -1)
vpncmd 127.0.0.1:5555 /SERVER /CMD:DynamicDnsSetHostname $WORD
service vpnserver restart
vpncmd 127.0.0.1:5555 /SERVER /CMD:OpenVpnMakeConfig openvpn
unzip openvpn.zip
myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
rm -f *bridge_l2.ovpn
sed -i "s/\(vpn[0-9]*\).v4.softether.net/$myip/" *.ovpn
sed -i 's/udp/tcp/' *.ovpn
sed -i 's/1194/443/' *.ovpn
sed -i '/^\s*[@#]/ d' *.ovpn
sed -i '/^\s*[@;]/ d' *.ovpn
sed -i '/^\s*$/d' *.ovpn

clear
echo "\033[0;34mFinished Installing SofthEtherVPN."
echo "\033[1;34m"
echo "Go to the this url to get your OpenVPN config file"
echo "\033[1;33m"
cat *_remote*.ovpn | ./scrunge.sh
echo "\033[1;34m"
echo "Server WAN/Public IP address: ${myip}"
echo ""
echo "Username and Password pairs for the virtual hub VPN:"
echo "\033[1;35mvpn - vpn ; vpn1 - vpn1 ; vpn2 - vpn2 ; vpn3 - vpn3; vpn4 - vpn4"
echo "\033[1;34musername and password are the same"
echo ""
echo "Ports for SofthEther VPN:"
echo "SEVPN/OpenVPN TCP Ports: 80,82,443,995,992,5555,5242,4244,3128,9200,9201,21,137,8484"
echo "OpenVPN UDP Ports: 80,82,443,5242,4244,3128,9200,9201,21,137,8484,,5243,9785,2000-4499,4501-8000"
echo ""
echo "Please use the SE-Server Manager/vpncmd to set a server password for security purposes"
echo "\033[1;34myou can run this \033[0;35mvpncmd 127.0.0.1:5555 /SERVER /CMD:ServerPasswordSet \033[1;34mto set a password"
