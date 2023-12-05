#!/bin/sh

# We're testing in dry-run mode and testing homedir names only with arbitrary
# usernames and uid/gid pairs, because otherwise we'd have to run under sudo
# to actually do the chowns/chmods

user="gsamsa"
uid=2247
gid=200
mode="700"

# Assumes this is in "tests/" relative to initdir
CMD="$(dirname $(dirname $0))/initdir.sh"

topdir=""

# Sometimes I wish I didn't develop on MacOS and run my containers on Linux
# BSD stat and Linux stat are rather different
stat_fmt="-c"
stat_mode_flag="%a"
os=$(uname)
if [ "${os}" = "Darwin" ]; then
    stat_fmt="-f"
    stat_mode_flag="%p"
fi

check_dry_run() {
    if [ "${out}" != "${expected}" ]; then
        printf "Expected '${expected}', got '${out}'\n" 1>&2
        printf "FAIL\n"
        exit 1
    fi
    printf "ok\n"
}

generic_mktemp() {
    # First we try GNU mktemp, then BSD mktemp
    topdir=$(mktemp -d) || \
        topdir=$(mktemp -d "${TMPDIR:-/tmp}"tmp.XXXXXXXX)
    trap "rm -rf ${topdir}" EXIT
}

test_basic_dry_run() {
    printf "Testing basic functionality (dry run)..."
    homedir="/home/${user}"
    expected="${user}(${uid}:${gid}):${homedir}"
    out=$(JUPYTERHUB_USER="${user}" EXTERNAL_UID="${uid}" \
                         EXTERNAL_GID="${gid}" DRY_RUN=1 "${CMD}")
    check_dry_run
}

test_implicit_gid_dry_run() {
    printf "Testing implicit GID (dry run)..."
    homedir="/home/${user}"
    expected="${user}(${uid}:${uid}):${homedir}"
    out=$(JUPYTERHUB_USER="${user}" EXTERNAL_UID="${uid}" \
                         DRY_RUN=1 "${CMD}")
    check_dry_run
}

test_homedir_dry_run() {
    printf "Testing explicit homedir (dry run)..."
    homedir="/remote/home/g/${user}/nublado"
    expected="${user}(${uid}:${gid}):${homedir}"    
    out=$(JUPYTERHUB_USER="${user}" EXTERNAL_UID="${uid}" \
                         INITIAL_THEN_USER=1 \
                         HOMEDIR="/remote/home/g/${user}/nublado" \
                         EXTERNAL_GID="${gid}" DRY_RUN=1 "${CMD}")
    check_dry_run
}

check_real() {
    if [ ! -e "${homedir}" ]; then
        printf "${homedir} does not exist\n" 1>&2
        printf "FAIL\n"
        exit 3
    fi
    if [ ! -d "${homedir}" ]; then
        printf "${homedir} exists but is not a directory\n" 1>&2
        printf "FAIL\n" 
        exit 3
    fi
    # None of this should ever fail unless we run privileged and mess up
    # somehow.
    o_uid=$(stat ${stat_fmt} %u ${homedir})
    o_gid=$(stat ${stat_fmt} %g ${homedir})
    # MacOS uses the first three bits for file type.  100 is "regular".
    o_mode=$(stat ${stat_fmt} ${stat_mode_flag} ${homedir} | \
                 rev | cut -c 1-3 | rev)
    if [ "${o_uid}" -ne "${ruid}" ]; then
        printf "${homedir} exists but is owned by ${o_uid} " 1>&2
        printf "not ${ruid}\n" 1>&2
        printf "FAIL\n" 
        exit 4
    fi
    if [ "${o_gid}" -ne "${rgid}" ]; then
        printf "${homedir} exists but has group ${o_gid} " 1>&2
        printf "not ${rgid}\n" 1>&2
        printf "FAIL\n" 
        exit 4
    fi
    if [ "${o_mode}" != "${mode}" ]; then
        printf "${homedir} has wrong mode ${o_mode}, not ${mode}\n" 1>&2
        printf "FAIL\n"
        exit 4
    fi
    printf "ok\n"
}

test_basic_real() {
    printf "Testing basic functionality (real)..."
    homedir="${topdir}/${ruser}"
    out=$(JUPYTERHUB_USER="${ruser}" EXTERNAL_UID="${ruid}" \
                         HOMEDIR="${topdir}/${ruser}" \
                         EXTERNAL_GID="${rgid}" "${CMD}")
    check_real
}

test_basic_dry_run
test_implicit_gid_dry_run
test_homedir_dry_run

# Now we'll do it for real, but we have to use our own uid/gid if we
# don't want to test under sudo, which seems like a remarkably bad idea,
# and since we can't write to an arbitrary directory we'll need to make one
# and set HOMEDIR explicitly too.  That's why there's only one test.

ruser=$(whoami)
ruid=$(id -u)
rgid=$(id -g)

generic_mktemp

test_basic_real
