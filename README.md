# lsstsqre/initdir

Initializes a user's home directory, but as an initContainer, rather
than as something controlled by Moneypenny.

## Theory of Operation

This container will run with the same environment and volume mounts as
the notebook container--however, it will run with privilege.

It will consult the `JUPYTERHUB_USER`, `EXTERNAL_UID`, and
`EXTERNAL_GID` environment variables, and then construct a home
directory for the named user with that UID/GID pair, and set it to mode
0700.

This obviously requires that the NFS server on the far end be mounted
`no_root_squash` or the moral equivalent, if a different distributed
filesystem is used.

## Construction

This is simply a busybox image with an additional shell script to check
that the environment variables are present and that the directory, if
already present, is correctly owned.  The init container will warn if
the mode is not 0700, but will not consider that an error.

