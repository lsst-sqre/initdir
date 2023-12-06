#!/bin/sh
set -e

usage() {
    printf "Usage: $0\n" 1>&2
    printf "\n" 1>&2
    printf "\$JUPYTERHUB_USER and \$EXTERNAL_UID must be set\n" 1>&2
    printf "\$EXTERNAL_GID may be set; defaults to \$EXTERNAL_UID\n" 1>&2
    printf "\$HOMEDIR may be set; defaults to " 1>&2
    printf "\"/home/\$JUPYTERHUB_USER\"\n" 1>&2
    printf "\$DRY_RUN (print user info and directory) may be set; " 1>&2
    printf "defaults to off\n" 1>&2
}

# Make sure we were invoked with no argument
if [ -n "$1" ]; then
   usage
   exit 1
fi

# Sometimes I wish I didn't develop on MacOS and run my containers on Linux.
# BSD stat and Linux stat are rather different.
stat_fmt="-c"
stat_mode_flag="%a"
os=$(uname)
if [ "${os}" = "Darwin" ]; then
    stat_fmt="-f"
    stat_mode_flag="%p"
fi

# Read relevant environmental variables
if [ -z "${JUPYTERHUB_USER}" ]; then
    printf "JUPYTERHUB_USER is not set.  Cannot continue\n" 1>&2
    exit 2
fi
if [ -z "${EXTERNAL_UID}" ]; then
    printf "EXTERNAL_UID is not set.  Cannot continue\n" 1>&2
    exit 2
fi
EXTERNAL_GID=${EXTERNAL_GID:-${EXTERNAL_UID}}
HOMEDIR=${HOMEDIR:-/home/${JUPYTERHUB_USER}}
# Normalize homedir
first=$(echo "${HOMEDIR}" | cut -c 1)
if [ "${first}" != "/" ]; then
    HOMEDIR="/${HOMEDIR}"
fi
if [ -n "${DRY_RUN}" ]; then
    printf "${JUPYTERHUB_USER}(${EXTERNAL_UID}:${EXTERNAL_GID}):${HOMEDIR}\n"
    exit 0
fi
if [ -e "${HOMEDIR}" ]; then
    if [ ! -d "${HOMEDIR}" ]; then
        printf "${HOMEDIR} exists but is not a directory\n" 1>&2
        exit 3
    else
        # Already exists, check permissions
        r_uid=$(stat ${stat_fmt} %u ${HOMEDIR})
        r_gid=$(stat ${stat_fmt} %g ${HOMEDIR})
        # MacOS uses the first three bits for file type.  100 is "regular".
        r_mode=$(stat ${stat_fmt} ${stat_mode_flag} ${HOMEDIR} \
              rev | cut -c 1-3 | rev)
        if [ "${r_uid}" -ne "${EXTERNAL_UID}" ]; then
           printf "${HOMEDIR} exists but is owned by ${r_uid} " 1>&2
           printf "not ${EXTERNAL_UID}" 1>&2
           exit 4
        fi
        if [ "${r_gid}" -ne "${EXTERNAL_GID}" ]; then
           printf "${HOMEDIR} exists but has group ${r_gid} " 1>&2
           printf "not ${EXTERNAL_GID}" 1>&2
           exit 4
        fi
        if [ "${r_mode}" != "700" ]; then
            printf "${HOMEDIR} has suspicious permissions ${r_mode}" 1>&2
        fi
    fi
else
    # It doesn't exist.  Create it.  Force mode 700 with umask.
    umask 077
    mkdir -p "${HOMEDIR}"
    chown "${EXTERNAL_UID}:${EXTERNAL_GID}" "${HOMEDIR}"
fi
