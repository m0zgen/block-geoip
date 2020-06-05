#!/bin/bash
# Cretaed by Yevgeniy Gonvharov, https://sys-adm.in
# Block countries with ipset + firewalld script

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Vars
# ---------------------------------------------------\
IGNORE_COUNTRIES="ru pl kz de fr"
BLACKLIST_NAME="geoblacklist"
TMPDIR="/tmp/geoip"
DEBUG=true
STATUS="$(systemctl is-active firewalld.service)"

# Processing
# ---------------------------------------------------\

# Checking is firewalld is running
if [ "${STATUS}" = "active" ]; then
    echo -e "[\e[32mOK\e[39m] Firewalld is running!..."
else 
    echo -e "[\e[31mFAIL\e[39m] Firewalld does not running, aborting!" 
    exit 1  
fi

# Create the blacklist (only if necessary)
# 200k should be enough - $(find . -name "*.zone" | xargs wc -l) gives 184688 lines without the it zone
firewall-cmd --get-ipsets| grep "$BLACKLIST_NAME" > /dev/null 2> /dev/null 
if [[ $? -ne 0 ]];then
        echo -e "[\e[93mi\e[39m] Creating new ipset $BLACKLIST_NAME in the Firewall... "
        firewall-cmd --permanent --new-ipset="$BLACKLIST_NAME" --type=hash:net --option=family=inet --option=hashsize=4096 --option=maxelem=200000 > /dev/null 2> /dev/null 
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] Blacklist $BLACKLIST_NAME successfully created!"
    else
        echo -e "[\e[31mFAIL\e[39m] Couldn't create the blacklist $BLACKLIST_NAME, aborting!"
        exit 1
    fi
fi

# Create temporary folder
mkdir -p $TMPDIR

# Downloads the GeoIP database
if [[ $? -eq 0 ]];then
    echo -e "[\e[93mi\e[39m] Downloading latest ip database... "
       # wget http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz > /dev/null 2> /dev/null
	   wget -q --no-check-certificate http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz -O $TMPDIR/geoip.tar.gz > /dev/null 2> /dev/null
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

# Extract zones in to the temporary folder
tar -xzf $TMPDIR/geoip.tar.gz -C $TMPDIR

# Remove all excluded zones
for i in $IGNORE_COUNTRIES; do
    rm $TMPDIR/$i.zone
    echo -e "Remove $TMPDIR/$i.zone"
done

# Debug clean
if [[ $DEBUG ]]; then
    rm -rf $TMPDIR/[a-w]*.zone
fi

# Add the IPs to the blacklist
for f in $TMPDIR/*.zone; do
    echo -e "[\e[93mi\e[39m] Adding $f ..."
    firewall-cmd --permanent --ipset="$BLACKLIST_NAME" --add-entries-from-file=$f > /dev/null
    if [[ $? -eq 0 ]];then
        echo -e "[\e[32mOK\e[39m] Added $f with no issues";
    else
        echo -e "[\e[31mFAIL\e[39m] Some errors verified while adding the $f zone";
    fi
done

# Drop the IPs

STAT=$(firewall-cmd --list-all --zone=drop | grep "$BLACKLIST_NAME")
if [[ ! -z $STAT ]];then
    echo -e "[\e[32mOK\e[39m] Drop zone $BLACKLIST_NAME is exist"
else
    echo -e "[\e[93mi\e[39m] Adding source $BLACKLIST_NAME to DROP zone... "
    firewall-cmd --permanent --zone=drop --add-source="ipset:$BLACKLIST_NAME" > /dev/null
fi

# Reload the firewall
echo -e "[\e[93mi\e[39m] Reload firewalld... "
firewall-cmd --reload > /dev/null

# cd ~
# Remove the traces
rm -rf $TMPDIR

echo ""
echo -e "DONE!"