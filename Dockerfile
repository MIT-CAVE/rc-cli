# syntax = docker/dockerfile:1.2
ARG DOCKER_VERSION=20.10.2
ARG INPUTS_DIR=/data/inputs/
ARG OUTPUTS_DIR=/data/outputs/
ARG IMAGE_BASE_DIR=/solutions/

FROM docker:${DOCKER_VERSION}-dind
LABEL edu.mit.cave.rc.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.rc.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.rc.image.title="Routing Challenge Trainer"
LABEL edu.mit.cave.rc.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.rc.image.created="2021-02-01 20:10:58+02:00"
LABEL edu.mit.cave.rc.image.version="0.1.0"
ARG INPUTS_DIR
ARG OUTPUTS_DIR
ARG IMAGE_BASE_DIR
ENV INPUTS_DIR $INPUTS_DIR
ENV OUTPUTS_DIR $OUTPUTS_DIR
ENV IMAGE_BASE_DIR $IMAGE_BASE_DIR
RUN mkdir -p $IMAGE_BASE_DIR && mkdir -p $INPUTS_DIR && mkdir -p $OUTPUTS_DIR
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint-alt.sh
ENTRYPOINT ["docker-entrypoint-alt.sh"]
