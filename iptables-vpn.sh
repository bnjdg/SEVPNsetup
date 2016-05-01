#!/bin/sh
iptables -X
iptables -X -t nat
iptables -F 
iptables -F -t nat

##############################
### ATTACKS
##############################
# All TCP sessions should begin with SYN
iptables -A INPUT -p tcp ! --syn -m state --state NEW -s 0.0.0.0/0 -j DROP
# Limit the number of incoming tcp connections
# incoming syn-flood protection
iptables -N syn_flood
iptables -A INPUT -p tcp --syn -j syn_flood
iptables -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
iptables -A syn_flood -j DROP
# fragmented ICMP - sign of DoS attack
iptables -A INPUT --fragment -p ICMP -j DROP
#Limiting the incoming icmp ping request:
iptables -A INPUT -p icmp -m limit --limit  1/s --limit-burst 1 -j ACCEPT
iptables -A INPUT -p icmp -j DROP
iptables -A OUTPUT -p icmp -j ACCEPT
#Force Fragments packets check
iptables -A INPUT -f -j DROP
#Incoming malformed XMAS packets
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# Drop all NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# invalid and suspicious packets
iptables -A INPUT -m state --state INVALID -j DROP
# Stealth scan 1
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "FWLOG: Stealth scan (1): "
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# Stealth scan 2
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "FWLOG: Stealth scan (2): "
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# Stealth scan 3
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j LOG --log-prefix "FWLOG: Stealth scan (3): "
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
# Stealth scan 4
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j LOG --log-prefix "FWLOG: Stealth scan (4): "
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
# Stealth scan 5
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j LOG --log-prefix "FWLOG: Stealth scan (5): "
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
# Stealth scan 6
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j LOG --log-prefix "FWLOG: Stealth scan (6): "
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
# Port scan
iptables -N port-scan
iptables -A port-scan -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j RETURN
iptables -A port-scan -j DROP


iptables -A INPUT -i eth0 -m state --state NEW,ESTABLISHED,RELATED -p udp -m multiport --dports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -j ACCEPT
iptables -A INPUT -i eth0 -m state --state NEW,ESTABLISHED,RELATED -p tcp -m multiport --dports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m multiport --sports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m multiport --sports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -j ACCEPT

#minecraft
iptables -A INPUT -i eth0 -m state --state NEW,ESTABLISHED,RELATED -p tcp -m multiport --dports 25655:25680 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m multiport --sports 25655:25680 -m state --state RELATED,ESTABLISHED -j ACCEPT

#allow tun+
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A OUTPUT -o tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT


#redirect TNT ports to SoftEther VPN TCP
iptables -t nat -A PREROUTING -i eth0 -p tcp -m multiport --dports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -j REDIRECT --to-port 995
iptables -A INPUT -i eth0 -p tcp -m multiport --dports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m multiport --sports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p udp -m multiport --dports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -j REDIRECT --to-port 1194
iptables -A INPUT -i eth0 -p udp -m multiport --dports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m multiport --sports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p udp -m multiport --dports 5243,9785 -j REDIRECT --to-port 1194
iptables -A INPUT -i eth0 -p udp -m multiport --dports 5243,9785 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m multiport --sports 5243,9785 -m state --state ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p udp -m multiport --dports 2000:4499,4501:8000 -j REDIRECT --to-port 1194
iptables -A INPUT -i eth0 -p udp -m multiport --dports 2000:4499,4501:8000 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m multiport --sports 2000:4499,4501:8000 -m state --state ESTABLISHED -j ACCEPT


#allow ssh,www,https, letsencrypt

iptables -A OUTPUT -p tcp -m multiport --dports 22,80,443,54321 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m multiport --sports 22,80,443,54321 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 22,80,443,54321 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sports 22,80,443,54321 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

#rsync
iptables -A INPUT -p tcp --dport 873 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 873 -m state --state ESTABLISHED -j ACCEPT
#mysql
iptables -A INPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

iptables -A INPUT -i tap_soft -j ACCEPT
iptables -A OUTPUT -o tap_soft -j ACCEPT
iptables -A FORWARD -i tap_soft -j ACCEPT
iptables -A FORWARD -i tap_soft -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o tap_soft -m state --state RELATED,ESTABLISHED -j ACCEPT


iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp -m multiport --dports 53,67,68 -j ACCEPT
iptables -A INPUT -p udp -m multiport --sports 53,67,68 -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --dports 53,67,68 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --sports 53,67,68 -j ACCEPT


#nat
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.16.0.0/12 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE


#ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
#save rules
iptables-save > /etc/iptables/rules.v4
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf