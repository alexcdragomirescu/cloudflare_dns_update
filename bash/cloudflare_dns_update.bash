#!/bin/bash

baseDir=`dirname "$0"`

authEmail='someone@example.com'
authKey='0000000000000000000000000000000000000'

zoneName='example.com'
recordName='record.example.com'

curl='/usr/bin/curl -s'
date='/bin/date'
jq='/usr/bin/jq'

logFile="$baseDir/cloudflare_dns_update.log"

date_time=$($date)

wanip4=`$curl 'http://ipv4.icanhazip.com'`
wanip6=`$curl 'http://ipv6.icanhazip.com'`

zone_identifier=$(    
  $curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$zoneName" \
    -H "X-Auth-Email: $authEmail" \
    -H "X-Auth-Key: $authKey" \
    -H "Content-Type: application/json" \
    | $jq '.result[0].id' --raw-output
)

record_ip4=$(
  $curl -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$recordName&type=A" \
    -H "X-Auth-Email: $authEmail" \
    -H "X-Auth-Key: $authKey" \
    -H "Content-Type: application/json" \
    | $jq '.result[0].content' --raw-output
)

record_ip6=$(
  $curl -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$recordName&type=AAAA" \
    -H "X-Auth-Email: $authEmail" \
    -H "X-Auth-Key: $authKey" \
    -H "Content-Type: application/json" \
    | $jq '.result[0].content' --raw-output
)

echo ---------------------------------------- >> $logFile
echo Date Time: $date_time >> $logFile
echo ---------------------------------------- >> $logFile
echo Current IP4 Address: $wanip4 >> $logFile
echo Current IP4 Record: $record_ip4 >> $logFile
echo Current IP6 Address: $wanip6 >> $logFile
echo Current IP6 Record: $record_ip6 >> $logFile
echo ---------------------------------------- >> $logFile

if [ $wanip4 = $record_ip4 ]; then
  echo IPv4 Record matches. Update not needed. >> $logFile
else
  echo IPv4 Record does not match. Update needed. >> $logFile
  record_identifier=$(
    $curl -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$recordName&type=A" \
      -H "X-Auth-Email: $authEmail" \
      -H "X-Auth-Key: $authKey" \
      -H "Content-Type: application/json" \
      | $jq '.result[0].id' --raw-output
  )
  data_json="{\"type\":\"A\",\"name\":\"$recordName\",\"content\":\"$wanip4\"}"
  record_update=$(
    $curl -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
      -H "X-Auth-Email: $authEmail" \
      -H "X-Auth-Key: $authKey" \
      -H "Content-Type: application/json" \
      --data $data_json \
      | $jq '.success' --raw-output
  )
    
  echo IPv4 Record updated: $record_update >> $logFile
fi


if [ $wanip6 = $record_ip6 ]; then
  echo IPv6 Record matches. Update not needed. >> $logFile
else
  echo IPv6 Record does not match. Update needed. >> $logFile
  record_identifier=$(
    $curl -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$recordName&type=AAAA" \
      -H "X-Auth-Email: $authEmail" \
      -H "X-Auth-Key: $authKey" \
      -H "Content-Type: application/json" \
      | $jq '.result[0].id' --raw-output
  )
  data_json="{\"type\":\"AAAA\",\"name\":\"$recordName\",\"content\":\"$wanip6\"}"
  record_update=$(
    $curl -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
      -H "X-Auth-Email: $authEmail" \
      -H "X-Auth-Key: $authKey" \
      -H "Content-Type: application/json" \
      --data $data_json \
      | $jq '.success' --raw-output
  )
   
  echo IPv6 Record updated: $record_update >> $logFile
  
fi

echo ---------------------------------------- >> $logFile && echo >> $logFile

exit 0
