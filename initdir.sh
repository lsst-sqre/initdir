#!/bin/sh
set -e

usage() {
    printf "Usage: $0\n" 1>&2
}

# Make sure we were invoked with no argument
if [ -n "$1" ]; then
   usage
   exit 1
fi

# Read relevant environmental variables
if [ -z "${JUPYTERHUB_USER}" ]; then
    printf "JUPYTERHUB_USER is not set.  Cannot continue.\n" 1>&2
    exit 2
fi
if [ -z "${EXTERNAL_UID}" ]; then
    printf "EXTERNAL_UID is not set.  Cannot continue.\n" 1>&2
    exit 2
fi
if [ -z "${EXTERNAL_GID}" ]; then
    printf "EXTERNAL_GID is not set. Setting to EXTERNAL_UID.\n" 1>&2
    EXTERNAL_GID=${EXTERNAL_UID}
fi
homedirs="/home"
# Useful for testing
if [ -n "${HOMEDIR_OVERRIDE}" ]; then
    homedirs="${HOMEDIR_OVERRIDE}"
fi

homedir="${homedirs}/{$JUPYTERHUB_USER}"
if [ -e "${homedir}" ]; then
    if [ ! -d "${homedir}" ]; then
	printf "${homedir} exists but is not a directory.\n" 1>&2
	exit 3
    else
	# Already exists, check permissions
	r_uid=$(stat -c %u ${homedir})
	r_gid=$(stat -c %g ${homedir})
	r_mode=$(stat 0c %a ${homedir})
	if [ "${r_uid}" -ne "${EXTERNAL_UID}" ]; then
	   printf "${homedir} exists but is owned by ${r_uid} " 1>&2
	   printf "not ${EXTERNAL_UID}" 1>&2
	   exit 4
	fi
	if [ "${r_gid}" -ne "${EXTERNAL_GID}" ]; then
	   printf "${homedir} exists but has group ${r_gid} " 1>&2
	   printf "not ${EXTERNAL_GID}" 1>&2
	   exit 4
	fi
	if [ "${r_mode}" != "700" ]; then
	    printf "${homedir} has suspicious permissions ${r_mode}" 1>&2
	fi
    fi
else
    # It doesn't exist.  Create it.
    # We know that the homedir should already be mounted, and we are making
    # a top-level path, so we do not use mkdir -p
    mkdir "${homedir}"
    chmod 700 "${homedir}"
    chown "${EXTERNAL_UID}:${EXTERNAL_GID}" "${homedir}"
fi    
	    
	
