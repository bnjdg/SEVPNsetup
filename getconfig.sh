#!/bin/sh
rm -f *.ovpn *.pdf *.txt *.zip
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/globe.txt
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/tnt.txt
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/udp.txt
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/hpi.txt
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/injector.txt
vpncmd 127.0.0.1:5555 /SERVER /CMD:OpenVpnMakeConfig openvpn
unzip openvpn.zip
myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
GLOBE_MGC="$(cat globe.txt)"
TNT="$(cat tnt.txt)"
GLOBE_INET="$(cat udp.txt)"
INJ="$(cat injector.txt)"
HPI="$(cat hpi.txt)"
REMOTE="$(ls *remote*.ovpn)"
SRVHOSTNAMEGLOBE="$(hostname)_tcp_globe_mgc.ovpn"
SRVHOSTNAMETNT="$(hostname)_tcp_tnt.ovpn"
SRVHOSTNAMEUDP="$(hostname)_udp_globe_inet.ovpn"
SRVHOSTNAMEHPI="$(hostname)_tcp_hpi.ovpn"
SRVHOSTNAMEINJ="$(hostname)_tcp_injector.ovpn"
rm -f *bridge_l2.ovpn
cp $REMOTE $SRVHOSTNAMEGLOBE
cp $REMOTE $SRVHOSTNAMETNT
cp $REMOTE $SRVHOSTNAMEUDP
cp $REMOTE $SRVHOSTNAMEHPI
cp $REMOTE $SRVHOSTNAMEINJ
sed -i '/^\s*[@#]/ d' *.ovpn
sed -i '/^\s*[@;]/ d' *.ovpn
sed -i "s/\(vpn[0-9]*\).v4.softether.net/$myip/" *.ovpn
sed -i "s/v4.softether.net/softether.net/" *.ovpn
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
sed -i "s#<ca>#$INJ#" *tcp_injector.ovpn
sed -i "s#<ca>#$HPI#" *tcp_hpi.ovpn

clear
echo "\033[0;34mGenerating OpenVPN config files."
echo "\033[1;34m"
vpncmd 127.0.0.1:5555 /SERVER /CMD:DynamicDNSGetStatus
echo "Go to the these urls to get your OpenVPN config file"
echo "\033[1;33m"
echo Globe-mgc: $( cat *tcp_globe*.ovpn | sprunge )
echo TCP_TNT: $(cat *tcp_tnt*.ovpn | sprunge ) 
echo UDP_GLOBE: $( cat *udp*.ovpn | sprunge ) 
echo TCP_HPI: $(cat *tcp_hpi*.ovpn | sprunge ) 
echo TCP_INJECTOR: $(cat *tcp_injector*.ovpn | sprunge )
rm -f *.ovpn
echo "\033[1;34m"
echo "Don't forget to make a text file named account.txt to put your username"
echo "and your password, first line username. 2nd line password."
echo "\033[1;34m"
echo "Server WAN/Public IP address: ${myip}"
echo ""
echo "Username and Password pairs for the virtual hub VPN:"
echo "\033[1;35mvpn - vpn ; vpn1 - vpn1 ; vpn2 - vpn2 ; vpn3 - vpn3; vpn4 - vpn4"
echo "\033[1;34musername and password are the same"
echo ""
echo "Ports for SofthEther VPN:"
echo "SEVPN/OpenVPN TCP Ports: 80,82,443,995,992,5555,5242,4244,3128,9200,9201,21,137,8484,8080"
echo "OpenVPN UDP Ports: 80,82,443,5242,4244,3128,9200,9201,21,137,8484,,5243,9785,2000-4499,4501-8000"
echo ""
echo "\033[0m"
