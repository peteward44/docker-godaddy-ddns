#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SUCCESS_FILE=/tmp/status.success
source $DIR/env.sh

rm -f "$SUCCESS_FILE"

# GoDaddy.sh v1.0 by Nazar78 @ TeaNazaR.com
###########################################
# Simple DDNS script to update GoDaddy's DNS. Just schedule every 5mins in crontab.
# With options to run scripts/programs/commands on update failure/success.
#
# Requirements:
# - curl CLI - On Debian, apt-get install curl
#
# History:
# v1.0 - 20160513 - 1st release.
#
# PS: Feel free to distribute but kindly retain the credits (-:
###########################################

# Begin settings
# Get the Production API key/secret from https://developer.godaddy.com/keys/.
# Ensure it's for "Production" as first time it's created for "Test".
Key=$GODADDY_KEY
Secret=$GODADDY_SECRET

# Domain to update.
Domain=$GODADDY_DOMAIN

# Advanced settings - change only if you know what you're doing :-)
# Record type, as seen in the DNS setup page, default A.
if [ -z "$GODADDY_TYPE" ];then
	Type=A
else
	Type=$GODADDY_TYPE
fi

# Record name, as seen in the DNS setup page, default @.
if [ -z "$GODADDY_NAME" ];then
	Name=@
else
	Name=$GODADDY_NAME
fi

# Time To Live in seconds, minimum default 600 (10mins).
# If your public IP seldom changes, set it to 3600 (1hr) or more for DNS servers cache performance.
TTL=600

# Writable path to last known Public IP record cached. Best to place in tmpfs.
CachedIP=/tmp/current_ip

# External URL to check for current Public IP, must contain only a single plain text IP.
# Default https://api.ipify.org.
CheckURL=https://api.ipify.org
# End settings

function onfail {
   exit 1
}

function onsuccess {
   touch "$SUCCESS_FILE"
   exit 0
}

Curl=$(/usr/bin/which curl 2>/dev/null)
[ "${Curl}" = "" ] &&
echo "Error: Unable to find 'curl CLI'." && onfail
[ -z "${Key}" ] || [ -z "${Secret}" ] &&
echo "Error: Requires API 'Key/Secret' value." && onfail
[ -z "${Domain}" ] &&
echo "Error: Requires 'Domain' value." && onfail
[ -z "${Type}" ] && Type=A
[ -z "${Name}" ] && Name=@
[ -z "${TTL}" ] && TTL=600
[ "${TTL}" -lt 600 ] && TTL=600
#/usr/bin/touch ${CachedIP} 2>/dev/null
#[ $? -ne 0 ] && echo "Error: Can't write to ${CachedIP}." && exit 1
[ -z "${CheckURL}" ] && CheckURL=https://api.ipify.org
echo -n "Checking current 'Public IP' from '${CheckURL}'..."
PublicIP=$(${Curl} -kLs ${CheckURL})
if [ $? -eq 0 ] && [[ "${PublicIP}" =~ [0-9]{1,3}\.[0-9]{1,3} ]];then
  echo "${PublicIP}!"
else
  echo "Fail! ${PublicIP}"
  onfail
fi
if [ "$(cat ${CachedIP} 2>/dev/null)" != "${PublicIP}" ];then
  echo -n "Checking '${Domain}' IP records from 'GoDaddy'..."
  Check=$(${Curl} -kLsH"Authorization: sso-key ${Key}:${Secret}" \
  -H"Content-type: application/json" \
  https://api.godaddy.com/v1/domains/${Domain}/records/${Type}/${Name} \
  2>/dev/null|grep -Eo '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' 2>/dev/null)
  if [ $? -eq 0 ] && [ "${Check}" = "${PublicIP}" ];then
    echo -n ${Check}>${CachedIP}
    echo -e "unchanged!\nCurrent 'Public IP' matches 'GoDaddy' records. No update required!"
    onsuccess
  else
    echo -en "changed!\nUpdating '${Domain}'..."
    Update=$(${Curl} -kLsXPUT -H"Authorization: sso-key ${Key}:${Secret}" \
    -H"Content-type: application/json" -w"%{http_code}" -o/dev/null \
    https://api.godaddy.com/v1/domains/${Domain}/records/${Type}/${Name} \
    -d"[{\"data\":\"${PublicIP}\",\"ttl\":${TTL}}]" 2>/dev/null)
    if [ $? -eq 0 ] && [ "${Update}" -eq 200 ];then
      echo -n ${PublicIP}>${CachedIP}
      echo "Success!"
      onsuccess
    else
      echo "Fail! HTTP_ERROR:${Update}"
      onfail
    fi
  fi
else
  echo "Current 'Public IP' matches 'Cached IP' recorded. No update required!"
  onsuccess
fi
exit $?
