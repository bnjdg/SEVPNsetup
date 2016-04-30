# Readme

A shell script to install VPN using SoftEther on Ubuntu VPS like DigitalOcean

## Execution

* Execution for installation and setup

```shell
sudo su
wget bit.ly/sevpnsetup
sh setup.sh
```

The SoftEther VPN server is preset to have one VirtualHub and one account in it named vpn with password vpn
Also the server is configured to have a tap interface named tap_soft and the script also sets this up
with ip address of 172.16.0.1 and dhcp begins with 172.16.1.1 to 172.16.10.254
DNS Masq is configured to have Safe DNS servers with filters.

