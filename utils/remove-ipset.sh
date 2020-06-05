#!/bin/bash
# Cretaed by Yevgeniy Gonvharov, https://sys-adm.in
# Remove ipset from drop zone

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Vars
# ---------------------------------------------------\
BLACKLIST_NAME="geoblacklist"

# Processing
# ---------------------------------------------------\

# Remove ipset
irewall-cmd --permanent --zone=drop --remove-source="ipset:$BLACKLIST_NAME"
firewall-cmd --permanent --delete-ipset=$BLACKLIST_NAME
firewall-cmd --reload