# lsstsqre/initdir

Initializes a user's home directory, as an initContainer.  It expects to
run with privilege, and in particular, with the ability to write as
root, or the equivalent, to the directory containing the user's home.

## Theory of Operation

The `initdir` container will run with the same home directory mount as
the notebook container--however, it will usually run with privilege,
which the notebook should not.

It will consult the `JUPYTERHUB_USER`, and `EXTERNAL_UID` variables,
which are required for it to run. 

It will additionally look for the `EXTERNAL_GID` and `HOMEDIR`
environment variables; if they are missing, their values will be set to
`$EXTERNAL_UID` and `/home/$JUPYTERHUB_USER` respectively.

If the `DRY_RUN` environment variable is not empty, the container will print
`$HOMEDIR` to its standard output and exit.

Otherwise, it will then construct a home directory for the named user
with that UID/GID pair, and will then set that to mode `0700`.

Normal operation requires that the NFS server on the far end be mounted
`no_root_squash` or the moral equivalent, if a different volume type is
used.  This also requires that `initdir` be running with privilege.

## Construction

This is simply a busybox image with an additional shell script to check
that the environment variables are present and that the directory, if
already present, is correctly owned.  The init container will warn if
the mode is not `0700`, but will not consider that an error.


