# Readme

A shell script to install VPN using SoftEther and Transmission CLI Torrent Client on Ubuntu 14.04 for use on Digital Ocean

## Execution

* Execution for installation and setup

```shell
sudo su
wget ayush.sachdev.me/DigitalOceanVPN
sh DigitalVPN
```

The SoftEther VPN server is preset to have one VirtualHub and one account in it named vpn with password vpn
Also the server is configured to have a tap interface named tap_soft and the script also sets this up
