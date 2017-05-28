#!/bin/sh
DEF_IF=$(route | grep '^default' | grep -o '[^ ]*$')
ip6tables -P INPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -X
ip6tables -X -t nat
ip6tables -F
ip6tables -F -t nat

##############################
### ATTACKS
##############################
# All TCP sessions should begin with SYN
ip6tables -A INPUT -p tcp ! --syn -m state --state NEW -s 0.0.0.0/0 -j DROP
# Limit the number of incoming tcp connections
# incoming syn-flood protection
ip6tables -N syn_flood
ip6tables -A INPUT -p tcp --syn -j syn_flood
ip6tables -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
ip6tables -A syn_flood -j DROP
# fragmented ICMP - sign of DoS attack
#ip6tables -A INPUT --fragment -p ICMP -j DROP
#Limiting the incoming icmp ping request:
ip6tables -A INPUT -p icmp -m limit --limit  1/s --limit-burst 1 -j ACCEPT
ip6tables -A INPUT -p icmp -j DROP
ip6tables -A OUTPUT -p icmp -j ACCEPT
#Force Fragments packets check
#ip6tables -A INPUT -f -j DROP
#Incoming malformed XMAS packets
ip6tables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# Drop all NULL packets
ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# invalid and suspicious packets
ip6tables -A INPUT -m state --state INVALID -j DROP
# Stealth scan 1
ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "FWLOG: Stealth scan (1): "
ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# Stealth scan 2
ip6tables -A INPUT -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "FWLOG: Stealth scan (2): "
ip6tables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# Stealth scan 3
ip6tables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j LOG --log-prefix "FWLOG: Stealth scan (3): "
ip6tables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
# Stealth scan 4
ip6tables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j LOG --log-prefix "FWLOG: Stealth scan (4): "
ip6tables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
# Stealth scan 5
ip6tables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j LOG --log-prefix "FWLOG: Stealth scan (5): "
ip6tables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
# Stealth scan 6
ip6tables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j LOG --log-prefix "FWLOG: Stealth scan (6): "
ip6tables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
# Port scan
ip6tables -N port-scan
ip6tables -A port-scan -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j RETURN
ip6tables -A port-scan -j DROP


ip6tables -A INPUT -i $DEF_IF -m state --state NEW,ESTABLISHED,RELATED -p udp -m multiport --dports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -j ACCEPT
ip6tables -A INPUT -i $DEF_IF -m state --state NEW,ESTABLISHED,RELATED -p tcp -m multiport --dports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p tcp -m multiport --sports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p udp -m multiport --sports 22,80,443,995,5555,400,500,4500,1701,1194:1196,9091 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -i $DEF_IF -m state --state NEW,ESTABLISHED,RELATED -p udp -m multiport --dports 993,8080,3128 -j ACCEPT
ip6tables -A INPUT -i $DEF_IF -m state --state NEW,ESTABLISHED,RELATED -p tcp -m multiport --dports 993,8080,3128 -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p tcp -m multiport --sports 993,8080,3128  -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p udp -m multiport --sports 993,8080,3128 -m state --state RELATED,ESTABLISHED -j ACCEPT

ip6tables -A OUTPUT -p udp -o $DEF_IF -j ACCEPT
ip6tables -A INPUT -p udp -i $DEF_IF -j ACCEPT

#minecraft
ip6tables -A INPUT -i $DEF_IF -m state --state NEW,ESTABLISHED,RELATED -p tcp -m multiport --dports 25655:25680 -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p tcp -m multiport --sports 25655:25680 -m state --state RELATED,ESTABLISHED -j ACCEPT

#allow tun+
ip6tables -A INPUT -i tun+ -j ACCEPT
ip6tables -A OUTPUT -o tun+ -j ACCEPT
ip6tables -A FORWARD -i tun+ -j ACCEPT
ip6tables -A FORWARD -i tun+ -o $DEF_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i $DEF_IF -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i tun+ -o ens0 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i ens0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT

#redirect TNT ports to SoftEther VPN TCP
ip6tables -t nat -A PREROUTING -i $DEF_IF -p tcp -m multiport --dports 5242,4244,9200,9201,21,137,8484,82 -j REDIRECT --to-port 995
ip6tables -A INPUT -i $DEF_IF -p tcp -m multiport --dports 5242,4244,9200,9201,21,137,8484,82 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p tcp -m multiport --sports 5242,4244,9200,9201,21,137,8484,82 -m state --state ESTABLISHED -j ACCEPT

ip6tables -t nat -A PREROUTING -i $DEF_IF -p udp -m multiport --dports 5242,4244,3128,9200,9201,21,137,8484,82 -j REDIRECT --to-port 1194
ip6tables -A INPUT -i $DEF_IF -p udp -m multiport --dports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p udp -m multiport --sports 5242,4244,3128,9200,9201,21,137,8484,82,443,80 -m state --state ESTABLISHED -j ACCEPT

ip6tables -t nat -A PREROUTING -i $DEF_IF -p udp -m multiport --dports 5243,9785 -j REDIRECT --to-port 1194
ip6tables -A INPUT -i $DEF_IF -p udp -m multiport --dports 5243,9785 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p udp -m multiport --sports 5243,9785 -m state --state ESTABLISHED -j ACCEPT

ip6tables -t nat -A PREROUTING -i $DEF_IF -p udp -m multiport --dports 2000:4499,4501:8000 -j REDIRECT --to-port 1194
ip6tables -A INPUT -i $DEF_IF -p udp -m multiport --dports 2000:4499,4501:8000 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p udp -m multiport --sports 2000:4499,4501:8000 -m state --state ESTABLISHED -j ACCEPT

ip6tables -t nat -A PREROUTING -i $DEF_IF -p tcp -m multiport --dports 65000:65500 -j REDIRECT --to-port 8387
ip6tables -A INPUT -i $DEF_IF -p tcp -m multiport --dports 8387,8388,65000:65500 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -o $DEF_IF -p tcp -m multiport --sports 8387,8388,65000:65500 -m state --state ESTABLISHED -j ACCEPT

#allow ssh,www,https, letsencrypt

ip6tables -A OUTPUT -p tcp -m multiport --dports 22,80,443,54321 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp -m multiport --sports 22,80,443,54321 -m state --state ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp -m multiport --dports 22,80,443,54321 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -p tcp -m multiport --sports 22,80,443,54321 -m state --state ESTABLISHED -j ACCEPT

ip6tables -A OUTPUT -p tcp -m multiport --dports 995,3128,992,5555,8080 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp -m multiport --sports 995,3128,992,5555,8080 -m state --state ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp -m multiport --dports 995,3128,992,5555,8080 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -p tcp -m multiport --sport 995,3128,992,5555,8080 -m state --state ESTABLISHED -j ACCEPT

ip6tables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

#rsync
ip6tables -A INPUT -p tcp --dport 873 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -p tcp --sport 873 -m state --state ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p tcp --dport 51413 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -p tcp --sport 51413 -m state --state ESTABLISHED -j ACCEPT

#mysql
ip6tables -A INPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

ip6tables -A INPUT -i tap_soft -j ACCEPT
ip6tables -A OUTPUT -o tap_soft -j ACCEPT
ip6tables -A FORWARD -i tap_soft -j ACCEPT
ip6tables -A FORWARD -i tap_soft -o $DEF_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i $DEF_IF -o tap_soft -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i tap_soft -o ens0 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -i ens0 -o tap_soft -m state --state RELATED,ESTABLISHED -j ACCEPT

ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT
ip6tables -A OUTPUT -p udp -m multiport --dports 53,67,68 -j ACCEPT
ip6tables -A INPUT -p udp -m multiport --sports 53,67,68 -j ACCEPT
ip6tables -A OUTPUT -p tcp -m multiport --dports 53,67,68 -j ACCEPT
ip6tables -A INPUT -p tcp -m multiport --sports 53,67,68 -j ACCEPT

ip6tables -A OUTPUT -p udp -m multiport --dports 60000:61000 -j ACCEPT
ip6tables -A INPUT -p udp -m multiport --sports 60000:61000 -j ACCEPT
ip6tables -A OUTPUT -p tcp -m multiport --dports 60000:61000 -j ACCEPT
ip6tables -A INPUT -p tcp -m multiport --sports 60000:61000 -j ACCEPT

#ping
ip6tables -A INPUT -p icmp -j ACCEPT
ip6tables -A OUTPUT -p icmp -j ACCEPT

ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP
ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
#save rules
ip6tables-save > /etc/iptables/rules.v6
