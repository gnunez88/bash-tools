#!/bin/bash
# Note: It only sends ICMP type 8 packets to C-classfull valid hosts.
TARGET="${1:?Target IP missing}"
IP=$(echo "${TARGET}" | grep -oP '\d{1,3}(\.\d{1,3}){2}')

function usage(){
    SCRIPT_NAME="$(basename $0)"
    echo -e "Usage:\v${SCRIPT_NAME} <Network IP>" >&2
    exit 1
}
function ctrl_c(){
    echo -e "\n[+] Exiting..."
    tput cnorm  # Show back the cursor
    exit
}
trap ctrl_c SIGINT

tput civis  # Hide the cursor
for i in $(seq 1 254); do
    ping -qnc1 -w1 ${IP}.${i} >/dev/null 2>&1 && echo -e "${IP}.${i}" &
done; wait
tput cnorm  # Show back the cursor
