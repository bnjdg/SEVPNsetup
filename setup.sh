#!/bin/sh
# SE-VPN script
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y unzip curl git dnsmasq bc make gcc openssl build-essential iptables-persistent haproxy squid

service vpnserver stop
killall vpnserver
killall vpnbridge
killall vpnclient
killall vpncmd
rm -rf SoftEtherVPN
git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git
cd SoftEtherVPN
sed -i 's#/usr/vpnserver#/opt/vpnserver#g' src/makefiles/linux_*.mak
sed -i 's#/usr/vpnclient#/opt/vpnclient#g' src/makefiles/linux_*.mak
sed -i 's#/usr/vpnbridge#/opt/vpnbridge#g' src/makefiles/linux_*.mak
sed -i 's#/usr/vpncmd/#/opt/vpncmd/#g' src/makefiles/linux_*.mak
sed -i 's#usr/vpncmd#opt/vpncmd#g' src/makefiles/linux_*.mak
./configure
make
make install
cp systemd/softether-vpnserver.service /etc/systemd/system/vpnserver.service
systemctl daemon-reload
systemctl enable vpnserver.service
systemctl stop squid
systemctl stop haproxy
cd ..

wget -O squid.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/squid.conf
mv /etc/squid/squid.conf /etc/squid/squid.conf.default
mv squid.conf /etc/squid/squid.conf

wget -O haproxy.cfg https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/haproxy.cfg
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.default
mv haproxy.cfg /etc/haproxy/haproxy.cfg

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/iptables-vpn.sh
chmod +x iptables-vpn.sh
sh iptables-vpn.sh
rm -f iptables-vpn.sh

wget -O /etc/dnsmasq.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/dnsmasq.conf
wget -O vpn_server.config https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/vpn_server.config
systemctl start vpnserver
vpncmd 127.0.0.1:5555 /SERVER /CMD:ConfigSet vpn_server.config
wget -O wordlist.txt https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/wordlist.txt
FILE=wordlist.txt
WORD=$(sort -R $FILE | head -1)
WORD2=$(sort -R $FILE | head -1)
vpncmd 127.0.0.1:5555 /SERVER /CMD:DynamicDnsSetHostname $WORD$WORD2
systemctl restart vpnserver
TAP_ADDR=172.16.0.1
TAP_SM=255.240.0.0
ifconfig tap_soft $TAP_ADDR netmask $TAP_SM
systemctl restart dnsmasq
systemctl restart squid
systemctl restart haproxy
rm -f vpn_server.config

wget -O /usr/bin/sprunge https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/sprunge.sh
chmod 755 /usr/bin/sprunge
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/globe.txt
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/tnt.txt
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/udp.txt
vpncmd 127.0.0.1:5555 /SERVER /CMD:OpenVpnMakeConfig openvpn
unzip openvpn.zip
myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
GLOBE_MGC="$(cat globe.txt)"
TNT="$(cat tnt.txt)"
GLOBE_INET="$(cat udp.txt)"
REMOTE="$(ls *remote*.ovpn)"
SRVHOSTNAMEGLOBE="$(hostname)_tcp_globe_mgc.ovpn"
SRVHOSTNAMETNT="$(hostname)_tcp_tnt.ovpn"
SRVHOSTNAMEUDP="$(hostname)_udp_globe_inet.ovpn"
rm -f *bridge_l2.ovpn
cp $REMOTE $SRVHOSTNAMEGLOBE
cp $REMOTE $SRVHOSTNAMETNT
cp $REMOTE $SRVHOSTNAMEUDP
sed -i '/^\s*[@#]/ d' *.ovpn
sed -i '/^\s*[@;]/ d' *.ovpn
sed -i "s/\(vpn[0-9]*\).v4.softether.net/$myip/" *.ovpn
sed -i 's/udp/tcp/' *tcp*.ovpn
sed -i 's/1194/443/' *tcp*.ovpn
sed -i 's/tcp/udp/' *udp*.ovpn
sed -i 's/1194/9201/' *udp*.ovpn
sed -i 's/443/9201/' *udp*.ovpn
sed -i 's/auth-user-pass/auth-user-pass account.txt/' *.ovpn
sed -i '/^\s*$/d' *.ovpn
sed -i "s#<ca>#$GLOBE_MGC#" *tcp_globe_mgc.ovpn
sed -i "s#<ca>#$TNT#" *tcp_tnt.ovpn
sed -i "s#<ca>#$GLOBE_INET#" *udp_globe_inet.ovpn

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/getconfig.sh
chmod +x getconfig.sh
rm -f *.txt
rm -f *.pdf
TAP_ADDR=172.16.0.1
TAP_SM=255.240.0.0
ifconfig tap_soft $TAP_ADDR netmask $TAP_SM
service dnsmasq restart
ifconfig tap_soft | grep 172.16.0.1

clear
echo "\033[0;34mFinished Installing SofthEtherVPN."
echo "\033[1;34m"
echo "Go to the these urls to get your OpenVPN config file"
echo "\033[1;33m"
cat *tcp_globe*.ovpn | sprunge
cat *tcp_tnt*.ovpn | sprunge
cat *udp*.ovpn | sprunge
rm -f *.ovpn
echo "\033[1;34m"
echo "Don't forget to make a text file named account.txt to put your username"
echo "and your password, first line username. 2nd line password."
echo "\033[1;34m"
echo "Server WAN/Public IP address: ${myip}"
echo "Server WAN/Public URL: $WORD$WORD2.softether.net
echo ""
echo "Username and Password pairs for the virtual hub VPN:"
echo "\033[1;35mvpn - vpn ; vpn1 - vpn1 ; vpn2 - vpn2 ; vpn3 - vpn3; vpn4 - vpn4"
echo "\033[1;34musername and password are the same"
echo ""
echo "Ports for SofthEther VPN:"
echo "SEVPN/OpenVPN TCP Ports: 80,82,443,995,992,5555,5242,4244,3128,9200,9201,21,137,8484,8080"
echo "OpenVPN UDP Ports: 80,82,443,5242,4244,3128,9200,9201,21,137,8484,,5243,9785,2000-4499,4501-8000"
echo ""
echo "Please set your server password via SE-VPN Manager."
echo "\033[0m"
ifconfig tap_soft | grep 172.16.0.1
