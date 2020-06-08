### Block with GeoIP script

This script blocking countries from ipdeny *.zones lists. You can set ipset name with "BLACKLIST_NAME" variable.

### Requirements

* Firewall-cmd
* CentOS or Debian-based distro

Tested and works on:

* Centos 7
* Ubuntu 18

### Usage

```bash
./block.sh
```

### Variables

You can find several variables in the `block.sh`:
```bash
IGNORE_COUNTRIES="ru pl kz de fr"
BLACKLIST_NAME="geoblacklist"
DEBUG=false
```

* `IGNORE_COUNTRIES` - excluded conties list
* `BLACKLIST_NAME` - ipset name
* `DEBUG` - for testing purposes, if true, `block.sh` ignore variable `IGNORE_COUNTRIES` and add several w*.zone and z*.zone in to the blacklist

### Utils

Folder "Utils" contains bash scripts

* `./utils/remove-ipset.sh` - can delete blackist ipset
* `./utils/remove-ip-from-ipset.sh` - can remove subnet from blacklist ipset

NOTE: ipset name (variable $BLACKLIST_NAME) please change in to every script manually

### Excludes

Open script and set "IGNORE_COUNTRIES" variable

### Thanks

* https://gist.github.com/Pandry/
