# Version 0.0.1
# 30 January 2023
# Adam Thornton, athornton@lsst.org
FROM docker.io/library/busybox:latest
COPY initdir.sh /
CMD [ "/initdir.sh" ]
