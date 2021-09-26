#!/bin/bash
#
# This function retrieves the ports collected from a Nmap scan
# There are three sort of output files Nmap support:
# -oN: file.nmap
# -oG: file.gnmap
# -oX: file.xml
# This script can filter by UDP, TCP or both, as well as filter
# by open, filter and open|filter ports.
# After collecting the ports they are copied to the clipboard.
#
# Note: It was tested with one-target scans.
#
# Author: Gabriel Núñez

XCLIP=$(which xclip)
if [ $? -ne 0 ]; then
    echo -e "Install `xclip`."
    exit 1
fi

function copy_clipboard(){
    PORTS_IN="$1"
    HOST="$2"
    if [[ "$#" == 2 ]]; then
        PORTS="$(echo -n "$1" | xargs | tr ' ' ',' | tr -d '\n')"
        echo -en "${PORTS} ${HOST}" | ${XCLIP} -sel clip
    else
        echo -en "${PORTS_IN}" | xargs \
            | tr ' ' ',' \
            | tr -d '\n' \
            | ${XCLIP} -sel clip
    fi
}

# Extract the port section from an Nmap format output (.nmap)
function port_section(){
    FILE="$1"
    # When the -O option is used in Nmap we will likely need this pattern
    REGEX="(?s)(?<=SERVICE\n)\d.+?(?=\nWarning:)"
    #{ OUTPUT="$(grep -oPz ${REGEX} ${FILE})"; } 2>/dev/null
    OUTPUT="$(grep -oPz ${REGEX} ${FILE} | tr -d '\0')";  # A better solution
    if [[ "${#OUTPUT}" -eq 0 ]]; then
        # When the option -O is not used in Nmap we'll likely need this pattern
        REGEX="(?s)(?<=SERVICE\n)\d.+?(?=\n\n)"
        #{ OUTPUT="$(grep -oPz ${REGEX} ${FILE} 2>/dev/null)"; } 2>/dev/null
        OUTPUT="$(grep -oPz ${REGEX} ${FILE} | tr -d '\0')";  # A better solution
    fi
    # If OUTPUT is still 0, the --reason might have been used, which changes headers
    if [[ "${#OUTPUT}" -eq 0 ]]; then
        REGEX="(?s)(?<=REASON\n)\d.+?(?=\nWarning:)"
        OUTPUT="$(grep -oPz ${REGEX} ${FILE} | tr -d '\0')";  # A better solution
    fi
    if [[ "${#OUTPUT}" -eq 0 ]]; then
        # When the option -O is not used in Nmap we'll likely need this pattern
        REGEX="(?s)(?<=REASON\n)\d.+?(?=\n\n)"
        #{ OUTPUT="$(grep -oPz ${REGEX} ${FILE} 2>/dev/null)"; } 2>/dev/null
        OUTPUT="$(grep -oPz ${REGEX} ${FILE} | tr -d '\0')";  # A better solution
    fi
    echo -e "${OUTPUT}"
}

function get_ports(){
    FILE="$1"
    FORM="$2"   # File format
    STAT="$3"   # Status
    PROT="$4"   # Protocol
    IPaddr="$5"   # Whether or not to copy the IP address

    # NMAP
    if [[ "${FORM}" == "nmap" ]]; then
        PORT_SECTION="$(port_section ${FILE})"
        if [[ "${STAT}" == "open" ]]; then
            PORT_PROTO="$(echo -e "${PORT_SECTION}" | awk '$2 ~ /open(|filtered)?/ {print $1}')"
            case "${PROT}" in
                tcp)  REGEX="^\d+(?=/tcp)";;
                udp)  REGEX="^\d+(?=/udp)";;
                *)    REGEX="^\d+(?=/(tcp|udp))";;
            esac
        elif [[ "${STAT}" == "filtered" ]]; then
            PORT_PROTO="$(echo -e "${PORT_SECTION}" | awk '$2 == "filtered" {print $1}')"
            case "${PROT}" in
                tcp)  REGEX="^\d+(?=/tcp)";;
                udp)  REGEX="^\d+(?=/udp)";;
                *)    REGEX="^\d+(?=/(tcp|udp))";;
            esac
        else
            PORT_PROTO="$(echo -e "${PORT_SECTION}" | awk '$2 ~ /open|filtered/ {print $1}')"
            case "${PROT}" in
                tcp)  REGEX="^\d+(?=/tcp)";;
                udp)  REGEX="^\d+(?=/udp)";;
                *)    REGEX="^\d+(?=/(tcp|udp))";;
            esac
        fi
        PORTS="$(echo -e "${PORT_PROTO}" | grep -oP ${REGEX})"

        if [[ ${IPaddr} == true ]]; then
            IPREG='(?<=^Nmap scan report for )(\d{1,3}\.){3}\d{1,3}'
            HOST="$(grep -m1 -oP "${IPREG}" "${FILE}")"
            if [[ ${#HOST} -eq 0 ]]; then
                IPREG6='(?<=^Nmap scan report for )([a-f0-9:]+$)'
                HOST="$(grep -m1 -oP "${IPREG6}" "${FILE}")"
            fi
        fi

    # GNMAP
    elif [[ "${FORM}" == "gnmap" ]]; then
        if [[ "${STAT}" == "open" ]]; then
            case "${PROT}" in
                tcp)  REGEX="\d+(?=/open/tcp//)";;
                udp)  REGEX="\d+(?=/open/udp//)";;
                *)    REGEX="\d+(?=/open/(tcp|udp)//)";;
            esac
        elif [[ "${STAT}" == "filtered" ]]; then
            case "${PROT}" in
                tcp)  REGEX="\d+(?=/filtered/tcp//)";;
                udp)  REGEX="\d+(?=/filtered/udp//)";;
                *)    REGEX="\d+(?=/filtered/(tcp|udp)//)";;
            esac
        else
            case "${PROT}" in
                tcp)  REGEX="\d+((?=/open/tcp//)|(?=/open\|filtered/tcp//))";;
                udp)  REGEX="\d+((?=/open/udp//)|(?=/open\|filtered/udp//))";;
                *)  REGEX="\d+((?=/open/(tcp|udp)//)|(?=/open\|filtered/(tcp|udp)//))";;
            esac
        fi
        PORTS="$(grep -oP ${REGEX} "${FILE}")"

        if [[ ${IPaddr} == true ]]; then
            IPREG='(?<=^Host: )(\d{1,3}\.){3}\d{1,3}'
            HOST="$(grep -m1 -oP "${IPREG}" "${FILE}")"
            if [[ ${#HOST} -eq 0 ]]; then
                IPREG6='(?<=^Host: )([a-f0-9:]+)'
                HOST="$(grep -m1 -oP "${IPREG6}" "${FILE}")"
            fi
        fi

    # XML
    elif [[ "${FORM}" == "xml" ]]; then
        if [[ "${STAT}" == "open" ]]; then
            case "${PROT}" in
                tcp)  REGEX='(?<=<port protocol="tcp" portid=")\d+(?="><state state="open")';;
                udp)  REGEX='(?<=<port protocol="udp" portid=")\d+(?="><state state="open")';;
                *)  REGEX='(?<=<port protocol="(tcp|udp)" portid=")\d+(?="><state state="open")';;
            esac
        elif [[ "${STAT}" == "filtered" ]]; then
            case "${PROT}" in
                tcp)  REGEX='(?<=<port protocol="tcp" portid=")\d+(?="><state state="filtered")';;
                udp)  REGEX='(?<=<port protocol="udp" portid=")\d+(?="><state state="filtered")';;
                *)  REGEX='(?<=<port protocol="(tcp|udp)" portid=")\d+(?="><state state="filtered")';;
            esac
        else
            case "${PROT}" in
                tcp)  REGEX='(?<=<port protocol="tcp" portid=")\d+(?="><state state="(open|filtered)")';;
                udp)  REGEX='(?<=<port protocol="udp" portid=")\d+(?="><state state="(open|filtered)")';;
                *)  REGEX='(?<=<port protocol="(tcp|udp)" portid=")\d+(?="><state state="(open|filtered)")';;
            esac
        fi
        PORTS="$(grep -oP "${REGEX}" "${FILE}")"

        if [[ ${IPaddr} == true ]]; then
            IPREG='(?<=^<address addr=")(\d{1,3}\.){3}\d{1,3}(?=" addrtype="ipv4"/>)'
            HOST="$(grep -m1 -oP "${IPREG}" "${FILE}")"
            if [[ ${#HOST} -eq 0 ]]; then
                IPREG6='(?<=^<address addr=")[a-f0-9:]+(?=" addrtype="ipv6"/>)'
                HOST="$(grep -m1 -oP "${IPREG6}" "${FILE}")"
            fi
        fi

    else
        echo -e "Something went wrong with the format."
        exit 1
    fi

    if [[ ${VERBOSE} ]]; then
        echo -e "[+] Ports: $(echo ${PORTS})"
        if [[ ${IP} ]]; then
            echo -e "[+] Host: $(echo ${HOST})"
        fi
    fi
    copy_clipboard "${PORTS}" "${HOST}"
}

# Options
optstring=":hv"     # Help message and verbosity
optstring+="oFa"    # Ports to filter
optstring+="ngx"    # File format
optstring+="tub"    # Protocol filter
optstring+="i"      # Copy the IPv4 address
optstring+="f:"     # File

## Default options
FILE=""
IP=false
FORMAT="nmap"
STATUS="all"
PROTOCOL="both"

while getopts ${optstring} arg; do
    case "${arg}" in
        h) help_message;;
        v) VERBOSE=true;;
        i) IP=true;;
        n) FORMAT="nmap";;
        g) FORMAT="gnmap";;
        x) FORMAT="xml";;
        o) STATUS="open";;
        F) STATUS="filtered";;
        a) STATUS="all";;
        t) PROTOCOL="tcp";;
        u) PROTOCOL="udp";;
        b) PROTOCOL="both";;
        f) FILE="${OPTARG}";;
        ?) echo "Invalid option: -${OPTARG}." >&2
           help_message;;
    esac
done

if [[ "${#FILE}" -eq 0 ]]; then
    echo -e "A file needs to be supplied (-f <filename>)"
    exit 1
fi

get_ports "${FILE}" ${FORMAT} ${STATUS} ${PROTOCOL} ${IP}
