#!/bin/bash
# SE-VPN script
echo "Updating system"
wget -O bash.bashrc https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/bash.bashrc
mv /etc/bash.bashrc /etc/bash.bashrc.default
mv bash.bashrc /etc/bash.bashrc
rm /home/*/.bashrc

wget -O dnsmasq.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/dnsmasq.conf
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.default
mv dnsmasq.conf /etc/dnsmasq.conf
systemctl stop dnsmasq

sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

wget https://github.com/tmux/tmux/releases/download/2.1/tmux-2.1.tar.gz
tar xvzf tmux-2.1.tar.gz
cd tmux-2.1
./configure
make && make install
cd

wget -O tmux.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/tmux.conf
cp tmux.conf /home/*/.tmux.conf
cp tmux.conf /root/.tmux.conf
rm tmux.conf

wget -O squid.conf https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/squid.conf
wget -O sony-domains.txt https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/sony-domains.txt
IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
sed -i "s/123.123.123.123/$IP/g" squid.conf
if [[ $DISTRO  =~ Debian ]]; then 
    mv /etc/squid3/squid.conf /etc/squid3/squid.conf.default;
    mv squid.conf /etc/squid3/squid.conf;
    mv sony-domains.txt /etc/squid3/sony-domains.txt
    sed -i '#/etc/squid/#/etc/squid3/#g' /etc/squid3/squid.conf
    ln -s /usr/bin/squid3 /usr/bin/squid
else 
    mv /etc/squid/squid.conf /etc/squid/squid.conf.default;
    mv squid.conf /etc/squid/squid.conf;
    mv sony-domains.txt /etc/squid/sony-domains.txt
fi

wget -O haproxy.cfg https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/haproxy.cfg
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.default
mv haproxy.cfg /etc/haproxy/haproxy.cfg

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/iptables-vpn.sh
chmod +x iptables-vpn.sh
sh iptables-vpn.sh

wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/getconfig.sh
chmod +x getconfig.sh

mkdir -p /opt/shadowsocks
wget https://github.com/shadowsocks/shadowsocks-go/releases/download/1.2.1/shadowsocks-server.tar.gz
tar xvzf shadowsocks-server.tar.gz
mv shadowsocks-server /opt/shadowsocks/
wget https://gist.githubusercontent.com/bjdag1234/971ba7d1f7834117e85a50d42c1d4bf5/raw/config.json
mv config.json /opt/shadowsocks/
