#!/bin/bash
SCRIPT_NAME="$(basename $0)"
CMD="ps -eo pid,user,cmd"
ARGS="${@:-Nothing to filter out}"
FILTER_OUT="${ARGS// /|}"

function usage(){
    echo -e "Usage:\v${SCRIPT_NAME}" >&2
    exit 1
}
function ctrl_c(){
    echo -e "\n[+] Exiting..."
    tput cnorm  # Show back the cursor
    exit
}
trap ctrl_c SIGINT

tput civis  # Hide the cursor
oldps=$(eval ${CMD})
while true; do
    newps=$(eval ${CMD})
    comm -13 <(echo "$oldps") <(echo "$newps") 2>/dev/null \
        | awk -v user=${USER} '$2 != user' \
        | grep -vE "$FILTER_OUT"
    oldps=$newps
done
tput cnorm  # Show back the cursor
