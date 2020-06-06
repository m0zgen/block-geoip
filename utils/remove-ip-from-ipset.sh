#!/bin/bash

BLACKLIST_NAME="geoblacklist"
me=`basename "$0"`

if [[ -z $1 ]]; then
	echo -e "Please determine ip. As exemple: ./$me xxx.xx.0.0/16"
	exit 1
else
	firewall-cmd --permanent --zone=drop --ipset=geoblacklist --remove-entry=$1
fi