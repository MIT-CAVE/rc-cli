# syntax = docker/dockerfile:1.2
ARG DOCKER_VERSION=20.10.3

FROM docker:${DOCKER_VERSION}-dind
LABEL edu.mit.cave.rct.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.rct.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.rct.image.title="Routing Challenge Trainer"
LABEL edu.mit.cave.rct.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.rct.image.created="2021-02-03 10:15:58+02:00"
LABEL edu.mit.cave.rct.image.version="0.1.0"
ENV INPUTS_DIR /data/inputs/
ENV OUTPUTS_DIR /data/outputs/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint-alt.sh
ENTRYPOINT ["docker-entrypoint-alt.sh"]
