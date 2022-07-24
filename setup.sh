#!/bin/bash

# Variables
## Messages
ERR_MSG="\e[1;37;41m"
GOOD_MSG="\e[1;32m"
RST_MSG="\e[0m"
## Paths
LOCALDIR="$(pwd)"
BASEDIR="${HOME}/.local"
SCRIPTDIR="${BASEDIR}/scripts"
BINDIR="${BASEDIR}/bin"

SCRIPTS=(
    get-ports.sh
    #hostscan.sh
    #portscan.sh
    #psdiff.sh
)

# Checking existence
[[ -d "${BINDIR}" ]] && BINDIR_OK=true || (mkdir -p "${BINDIR}" && BINDIR_OK=true)
[[ -d "${SCRIPTDIR}" ]] && SCRIPTDIR_OK=true || (mkdir -p "${SCRIPTDIR}" && SCRIPTDIR_OK=true)

if [[ "${BINDIR_OK}" = "true" && "${SCRIPTDIR_OK}" = "true" ]]; then
	for bashscript in "${SCRIPTS[@]}"; do
		SCRIPTNAME="$(basename ${bashscript} .sh)"
		cp -f "${bashscript}" "${SCRIPTDIR}/${bashscript}"
		ln -s -f "${SCRIPTDIR}/${bashscript}" "${BIN}/${SCRIPTNAME}"
		chmod +x "${SCRIPTDIR}/${bashscript}"
	done
	echo -e "${GOOD_MSG}Done!${RST_MSG}"
else
	echo -e "${ERR_MSG}Something went wrong!${RST_MSG}" >&2
	exit 1
fi

