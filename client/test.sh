#!/bin/sh

#
# Connect directly to the external services
#
# Expected result: connections successfully proxied by NGINX
#

NGINX=$(getent hosts app1 | awk '{ print $1 }')

trap ctrl_c ERR SIGINT SIGTERM

function ctrl_c() {
  stty echo
  exit 2
}

clear

echo -e "\033[1m====== Test Case 1: Request https://app1:443 with mTLS and SNI =====\033[0m\n"

echo -e "\033[1mConnect via OpenSSL with SNI but without client certificate and key (no mTLS) - should fail\033[0m\n" && stty -echo

command="openssl s_client -connect app1:443 -servername app1 -CAfile ca.crt -brief"
read -p "\$ $command" && echo -e "\n" && eval "echo 'Q' | $command"
echo -e "\n"

echo -e "\033[1mConnect via OpenSSL with SNI, client certificate and key (mTLS) - should succeed\033[0m\n"

command="openssl s_client -connect app1:443 -servername app1 -CAfile ca.crt -cert client.crt -key client.key -brief"
read -p "\$ $command" && echo -e "\n" && eval "echo 'Q' | $command" && echo -e "\n"

echo -e "\033[1mMake a curl request using mTLS and SNI - should receive HTTPS response payload\033[0m\n"

command="curl -o - -m 3 --resolve app1:443:$NGINX --cacert ca.crt --key client.key --cert client.crt https://app1:443/"
read -p "\$ $command" && echo -e "\n" && eval $command && echo -e "\n"

read -p "Press enter to continue..." && echo -e "\r\033[K" && stty echo


echo -e "\033[1m====== Test Case 2: Request https://app2:8000 with SNI =====\033[0m\n" && stty -echo

command="openssl s_client -connect app2:8000 -servername app2 -CAfile ca.crt -brief"
read -p "\$ $command" && echo -e "\n" && eval "echo 'Q' | $command" && echo -e "\n"

command="curl -o - -m 3 --resolve app2:8000:$NGINX --cacert ca.crt https://app2:8000/"
read -p "\$ $command" && echo -e "\n" && eval $command && echo -e "\n"

read -p "Press enter to continue..." && echo -e "\r\033[K" && stty echo


echo -e "\033[1m====== Test Case 3: Request https://app2:8000 using NGINX port 8001 (no SNI) =====\033[0m\n" && stty -echo

command="openssl s_client -connect app2:8001 -CAfile ca.crt -brief"
read -p "\$ $command" && echo -e "\n" && eval "echo 'Q' | $command" && echo -e "\n"

command="curl -o - -m 3 --cacert ca.crt https://app2:8001/"
read -p "\$ $command" && echo -e "\n" && eval $command && echo -e "\n"

read -p "Press enter to continue..." && echo -e "\r\033[K" && stty echo


echo -e "\033[1m====== Test Case 4: UDP connection to app2:123 via NGINX port 8002 =====\033[0m\n" && stty -echo

command="nc -u app2 8002"
read -p "\$ $command" && echo -e "\n" && stty echo
trap "" INT
eval $command
trap ctrl_c INT
echo -e "\n"

echo -e "\033[1m====== End of tests =====\033[0m\n"
stty echo
