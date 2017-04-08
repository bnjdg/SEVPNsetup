#!/bin/bash
useradd -M -s /usr/sbin/nologin $1
[[ -z $2 ]] && echo "$1:$2" | chpasswd || echo "$1:$1" | chpasswd