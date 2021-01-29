# syntax = docker/dockerfile:1.2
ARG DOCKER_VERSION=20.10.2
ARG INPUTS_DIR=/data/inputs/
ARG OUTPUTS_DIR=/data/outputs/
ARG IMAGE_BASE_DIR=/solutions/
ARG IMAGE_NAME=arc-hello.tar.gz

FROM docker:${DOCKER_VERSION}-dind
LABEL edu.mit.cave.arc.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.arc.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.arc.image.title="Algorithm Data Trainer for the Amazon Research Challenge"
LABEL edu.mit.cave.arc.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.arc.image.created="2021-01-29 13:15:38+02:00"
LABEL edu.mit.cave.arc.image.version="0.1.0"
ARG INPUTS_DIR
ARG OUTPUTS_DIR
ARG IMAGE_BASE_DIR
ENV INPUTS_DIR $INPUTS_DIR
ENV OUTPUTS_DIR $OUTPUTS_DIR
ENV IMAGE_BASE_DIR $IMAGE_BASE_DIR
RUN mkdir -p $IMAGE_BASE_DIR && mkdir -p $INPUTS_DIR && mkdir -p $OUTPUTS_DIR
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint-alt.sh
ARG IMAGE_NAME
ENV IMAGE_NAME $IMAGE_NAME
ENTRYPOINT ["docker-entrypoint-alt.sh"]
# ad-hoc command that will be executed separately from the docker-entrypoint
# CMD "some-command"
