#!/bin/bash
# SE-VPN script
echo "Updating system"
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
echo "Installing dependencies"
apt-get install -y unzip curl git dnsmasq bc make gcc openssl build-essential iptables-persistent haproxy tmux mosh
apt-get install -y libreadline-dev libncurses5-dev libssl-dev
DISTRO=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)
if [[ $DISTRO  =~ Debian ]]; then 
    echo deb http://httpredir.debian.org/debian jessie-backports main |  sed 's/\(.*-backports\) \(.*\)/&@\1-sloppy \2/' | tr @ '\n' | tee /etc/apt/sources.list.d/backports.list;
    curl https://haproxy.debian.net/bernat.debian.org.gpg | apt-key add -;
    echo deb http://haproxy.debian.net jessie-backports-1.6 main | tee /etc/apt/sources.list.d/haproxy.list;
    apt-get update;
    apt-get install -y haproxy -t jessie-backports;
    apt-get install -y squid3;
    apt-get install -y dnsutils;
 else apt-get install -y squid; fi

wget -O bash.bashrc https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/bash.bashrc
mv /etc/bash.bashrc /etc/bash.bashrc.default
mv bash.bashrc /etc/bash.bashrc
rm /home/*/.bashrc

wget -O dnsmasq.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/dnsmasq.conf
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.default
mv dnsmasq.conf /etc/dnsmasq.conf
systemctl stop dnsmasq

HOSTG=$(cat /etc/hosts | grep metadata.google.internal)
if [[ $HOSTG =~ metadata.google.internal ]]; then
    echo "server=169.254.169.254" >> /etc/dnsmasq.conf;
    sed -i 's/nameserver 127.0.0.1/nameserver 169.254.169.254/g' /etc/resolv.conf;
fi

fallocate -l 2G /swapfile
chmod 600 /swapfile 
mkswap /swapfile 
swapon /swapfile 
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
sudo sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/90-useroverrides.conf

( echo "127.0.1.1 $(cat /etc/hostname)" | tee -a /etc/hosts ) &>/dev/null
( echo "169.254.169.254 metadata.google.internal" | tee -a /etc/hosts ) &>/dev/null

wget -O tmux.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/tmux.conf

#Kill existing vpnservers
service vpnserver stop &>/dev/null
killall vpnserver &>/dev/null
killall vpnbridge &>/dev/null
killall vpnclient &>/dev/null
killall vpncmd &>/dev/null
rm -rf SoftEtherVPN &>/dev/null
rm -rf /opt/vpnserver &>/dev/null
rm -rf /usr/vpnserver &>/dev/null
rm -rf /opt/vpnbridge&>/dev/null
rm -rf /usr/vpnbridge &>/dev/null
rm -rf /opt/vpnclient &>/dev/null
rm -rf /usr/vpnclient &>/dev/null
rm -rf /opt/vpncmd &>/dev/null
rm -rf /usr/vpncmd &>/dev/null
rm -rf /usr/bin/vpnserver &>/dev/null
rm -rf /usr/bin/vpnclient &>/dev/null
rm -rf /usr/bin/vpncmd &>/dev/null
rm -rf /usr/bin/vpnbrige &>/dev/null
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
if [[ $DISTRO  =~ Debian ]]; then 
    mv /etc/squid/squid.conf /etc/squid/squid.conf.default;
    mv squid.conf /etc/squid/squid.conf;
    ln -s /usr/bin/squid3 /usr/bin/squid
else 
    mv /etc/squid3/squid.conf /etc/squid3/squid.conf.default;
    mv squid.conf /etc/squid3/squid.conf;
fi

wget -O haproxy.cfg https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/haproxy.cfg
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.default
mv haproxy.cfg /etc/haproxy/haproxy.cfg

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/iptables-vpn.sh
chmod +x iptables-vpn.sh
sh iptables-vpn.sh

curl https://getcaddy.com | bash
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/Caddyfile
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/index.html
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/caddy.service
mkdir -p /etc/caddy
mkdir -p /srv/www
mv Caddyfile /etc/caddy/
mv index.html /srv/www/
mv caddy.service /etc/systemd/system/
systemctl start caddy

systemctl start vpnserver
wget -O wordlist.txt https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/wordlist.txt
FILE=wordlist.txt
WORD=$(sort -R $FILE | head -1)
WORD2=$(sort -R $FILE | head -1)
vpncmd 127.0.0.1:5555 /server /cmd:hubdelete DEFAULT
vpncmd 127.0.0.1:5555 /server /cmd:hubcreate VPN /password:""
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:SetEnumDeny
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserDelete vpn
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn /group:"" /realname:vpn /note:vpnuser
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn1 /group:"" /realname:vpn /note:vpnuser
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn2 /group:"" /realname:vpn /note:vpnuser
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn3 /group:"" /realname:vpn /note:vpnuser
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn4 /group:"" /realname:vpn /note:vpnuser
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserCreate vpn5 /group:"" /realname:vpn /note:vpnuser
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserPasswordset vpn1 /password:vpn1
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserPasswordset vpn2 /password:vpn2
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserPasswordset vpn3 /password:vpn3
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserPasswordset vpn4 /password:vpn4
vpncmd 127.0.0.1:5555 /server /hub:VPN /cmd:UserPasswordset vpn5 /password:vpn5
vpncmd 127.0.0.1:5555 /server /cmd:bridgecreate VPN /device:soft /tap:yes
vpncmd 127.0.0.1:5555 /server /cmd:ListenerList
vpncmd 127.0.0.1:5555 /server /cmd:ListenerCreate 995
vpncmd 127.0.0.1:5555 /server /cmd:ListenerDelete 443
vpncmd 127.0.0.1:5555 /SERVER /CMD:DynamicDnsSetHostname $WORD$WORD2
systemctl restart vpnserver
systemctl restart dnsmasq

wget -O /usr/bin/sprunge https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/sprunge.sh
chmod 755 /usr/bin/sprunge
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

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/getconfig.sh
chmod +x getconfig.sh
echo "auto tap_soft\
iface tap_soft inet static\
    address 172.16.0.1\
    netmask 255.240.0.0" >> /etc/network/interfaces
TAP_ADDR=172.16.0.1
TAP_SM=255.240.0.0
ifconfig tap_soft $TAP_ADDR netmask $TAP_SM
ifconfig tap_soft | grep 172.16.0.1
systemctl restart dnsmasq
squid -k reconfigure
systemctl restart haproxy

clear
echo "\033[0;34mFinished Installing SofthEtherVPN."
echo "\033[1;34m"
vpncmd 127.0.0.1:5555 /SERVER /CMD:DynamicDNSGetStatus | tee -a SEVPN.setup
WORD3=$(sort -R $FILE | head -1)
WORD4=$(sort -R $FILE | head -1)
WORD5=$(sort -R $FILE | head -1)
SRVPASSWORD=$WORD3$WORD4$WORD5
touch SEVPN.setup
vpncmd 127.0.0.1:5555 /Server /cmd:serverpasswordset $SRVPASSWORD
echo "Go to the these urls to get your OpenVPN config file"
echo "\033[1;33m"
echo Globe-mgc: $( cat *tcp_globe*.ovpn | sprunge ) | tee -a SEVPN.setup
echo TCP_TNT: $(cat *tcp_tnt*.ovpn | sprunge ) | tee -a SEVPN.setup
echo UDP_GLOBE: $( cat *udp*.ovpn | sprunge ) | tee -a SEVPN.setup
echo TCP_HPI: $(cat *tcp_hpi*.ovpn | sprunge ) | tee -a SEVPN.setup
echo TCP_INJECTOR: $(cat *tcp_injector*.ovpn | sprunge )  | tee -a SEVPN.setup
rm -f *.ovpn
echo "\033[1;34m"
echo "Don't forget to make a text file named account.txt to put your username"
echo "and your password, first line username. 2nd line password."
echo "\033[1;34m"
echo "Server WAN/Public IP address: ${myip}" | tee -a SEVPN.setup
echo "Your password for SEVPN server admin is: $SRVPASSWORD" | tee -a SEVPN.setup
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
rm -f vpn_server.config
rm -f *.txt
rm -f iptables-vpn.sh
rm -f *.pdf
ifconfig tap_soft | grep 172.16.0.1