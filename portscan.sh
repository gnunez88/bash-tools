#!/bin/bash
TARGET="${1:?Target missing}"
FIRST_PORT="${2:-0}"
LAST_PORT="${3:-65535}"

function usage(){
    SCRIPT_NAME="${basename $0}"
    echo -e "Usage:\v${SCRIPT_NAME} <target> [<first-port> <last-port>]" >&2
    exit 1
}
function ctrl_c(){
    echo -e "\n[+] Exiting..."
    tput cnorm  # Show back the cursor
    exit
}
trap ctrl_c SIGINT

tput civis
for port in $(seq $FIRST_PORT $LAST_PORT); do
    bash -c "echo -n > /dev/tcp/${TARGET}/${port}" >/dev/null 2>&1 && echo "${port}" &
done; wait
tput cnorm
