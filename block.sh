#!/bin/bash

##
# Name: GeoIP Firewall script
# Author: Pandry
# Version: 0.1
# Description: This is a simple script that will set up a GeoIP firewall blocking all the zones excecpt the specified ones
#                it is possible to add the whitelisted zones @ line 47
# Additional notes: Usage of [iprange](https://github.com/firehol/iprange) is suggested
#                     for best performances
##

IGNORE_COUNTRIES="ru pl kz de fr"
BLACKLIST_NAME="geoblacklist"
TMPDIR="/tmp/geoip"
DEBUG=true


if [ $(which yum) ]; then
	echo -e "[\e[32mOK\e[39m] Detected a RHEL based environment!"
    echo -e "[\e[93mDOING\e[39m] Making sure firewalld is installed..."
    yum -y install firewalld > /dev/null 2> /dev/null
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] firewalld is installed!"
        systemctl start firewalld  > /dev/null 2> /dev/null
        systemctl enable firewalld  > /dev/null 2> /dev/null
    else
        echo -e "[\e[31mFAIL\e[39m] Couldn't install firewalld, aborting!"
        exit 1
    fi
elif [ $(which apt) ]; then
	echo -e "[\e[32mOK\e[39m] Detected a Debian based environment!"
    echo -e "[\e[93mDOING\e[39m] Making sure firewalld is installed..."
    apt -y install firewalld > /dev/null 2> /dev/null
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] firewalld is installed!"
        systemctl start firewalld  > /dev/null 2> /dev/null
        systemctl enable firewalld > /dev/null 2> /dev/null
    else
        echo -e "[\e[31mFAIL\e[39m] Couldn't install firewalld, aborting!"
        exit 1
    fi
fi

# Remove ipset
# firewall-cmd --permanent --zone=drop --remove-source="ipset:$BLACKLIST_NAME"
# firewall-cmd --permanent --delete-ipset=$BLACKLIST_NAME
# firewall-cmd --reload

#Create the blacklist (only if necessary)
#200k should be enough - $(find . -name "*.zone" | xargs wc -l) gives 184688 lines without the it zone
firewall-cmd --get-ipsets| grep "$BLACKLIST_NAME" > /dev/null 2> /dev/null 
if [[ $? -ne 0 ]];then
        echo -e "[\e[93mDOING\e[39m] Creating "
        firewall-cmd --permanent --new-ipset="$BLACKLIST_NAME" --type=hash:net --option=family=inet --option=hashsize=4096 --option=maxelem=200000 > /dev/null 2> /dev/null 
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] Blacklist $BLACKLIST_NAME successfully created!"
    else
        echo -e "[\e[31mFAIL\e[39m] Couldn't create the blacklist $BLACKLIST_NAME, aborting!"
        exit 1
    fi
fi

#create the folder
mkdir -p $TMPDIR

#Downloads the GeoIP database
if [[ $? -eq 0 ]];then
    echo -e "[\e[93mDOING\e[39m] Downloading latest ip database... "
    # wget http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz > /dev/null 2> /dev/null
	   wget --no-check-certificate http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz -O $TMPDIR/geoip.tar.gz
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] Database successfully downloaded!"
    else
        echo -e "[\e[31mFAIL\e[39m] Couldn't download the database, aborting!"
        exit 1
    fi
else 
    echo -e "[\e[31mFAIL\e[39m] Couldn't create the $TMPDIR directory!"
    exit 1
fi

#Extract the zones in the database
tar -xzf $TMPDIR/geoip.tar.gz -C $TMPDIR

#Remove all the zones you want to blacklist

for i in $IGNORE_COUNTRIES; do
    rm $TMPDIR/$i.zone
    echo -e "Remove $TMPDIR/$i.zone"
done

# Debug clean
if [[ $DEBUG ]]; then
    rm -rf $TMPDIR/[a-w]*.zone
fi

#Add the IPs to the blacklist
for f in $TMPDIR/*.zone; do
    echo -e "[\e[93mDOING\e[39m] Adding lines from $f ..."
    firewall-cmd --permanent --ipset="$BLACKLIST_NAME" --add-entries-from-file=$f > /dev/null
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] Added $f with no issues";
    else
        echo -e "[\e[31mFAIL\e[39m] Some errors verified while adding the $f zone";
    fi
    echo ""
done

# # Drop the IPs
firewall-cmd --permanent --zone=drop --add-source="ipset:$BLACKLIST_NAME" > /dev/null

# #Reload the firewall
firewall-cmd --reload

# cd ~
# Remove the traces
rm -rf $TMPDIR
