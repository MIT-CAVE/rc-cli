# syntax = docker/dockerfile:1.2
ARG DOCKER_VERSION=20.10.2
ARG SOURCE_DIR=/home/amzn/src/
ARG DATA_DIR=/data/
ARG OUTPUT_DIR=/output/
ARG IMAGE_BASE_DIR=/solutions/
ARG IMAGE_NAME=arc-hello.tar.gz

FROM docker:${DOCKER_VERSION}-dind
LABEL edu.mit.cave.basf.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.basf.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.basf.image.title="Algorithm Data Trainer for the Amazon Research Challenge"
LABEL edu.mit.cave.basf.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.amzn.image.created="2021-01-27 19:33:11+02:00"
LABEL edu.mit.cave.basf.image.version="0.1.0"
ARG SOURCE_DIR
ARG DATA_DIR
ARG OUTPUT_DIR
ARG IMAGE_BASE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV DATA_DIR $DATA_DIR
ENV OUTPUT_DIR $OUTPUT_DIR
ENV IMAGE_BASE_DIR $IMAGE_BASE_DIR
RUN addgroup -g 1000 amzn && adduser -u 1000 -G amzn -s /bin/sh -D amzn
RUN mkdir -p $SOURCE_DIR \
 && mkdir -p $IMAGE_BASE_DIR && chown amzn:amzn $IMAGE_BASE_DIR \
 && mkdir -p $DATA_DIR && chown amzn:amzn $DATA_DIR \
 && mkdir -p $OUTPUT_DIR && chown amzn:amzn $OUTPUT_DIR
WORKDIR $SOURCE_DIR
COPY --chown=arc:arc ./data/ $DATA_DIR
VOLUME $IMAGE_BASE_DIR $DATA_DIR $OUTPUT_DIR
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint-alt.sh
ARG IMAGE_NAME
ENV IMAGE_NAME $IMAGE_NAME
# USER amzn # only for dind-rootless
ENTRYPOINT ["docker-entrypoint-alt.sh"]
# ad-hoc command that will be executed separately from the docker-entrypoint
# CMD "some-command"
