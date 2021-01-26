# syntax = docker/dockerfile:1.2
ARG DOCKER_VERSION=20.10.2
ARG SOURCE_DIR=/home/amzn/
ARG MOUNT_DIR=/data/

FROM docker:${DOCKER_VERSION}
LABEL edu.mit.cave.basf.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.basf.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.basf.image.title="Algorithm Data Trainer for the Amazon Research Challenge"
LABEL edu.mit.cave.basf.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.amzn.image.created="2021-01-25 00:58:15+02:00"
LABEL edu.mit.cave.basf.image.version="0.1.0"
ARG SOURCE_DIR
ARG MOUNT_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV MOUNT_DIR $MOUNT_DIR
RUN addgroup -g 1000 amzn && adduser -u 1000 -G amzn -s /bin/sh -D amzn
RUN mkdir -p $SOURCE_DIR && mkdir -p $MOUNT_DIR && chown amzn:amzn $MOUNT_DIR
WORKDIR $SOURCE_DIR
COPY docker-entrypoint.sh /usr/local/bin/
USER amzn
VOLUME $MOUNT_DIR
ENTRYPOINT ["docker-entrypoint.sh"]
# ad-hoc command that will be executed separately from the docker-entrypoint
# CMD "some-command"
