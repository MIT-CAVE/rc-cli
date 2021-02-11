# syntax = docker/dockerfile:1.2
ARG DOCKER_VERSION=20.10.3

FROM docker:${DOCKER_VERSION}-dind
LABEL edu.mit.cave.tester.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.tester.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.tester.image.title="Routing Challenge Tester"
LABEL edu.mit.cave.tester.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.tester.image.created="2021-02-11 17:27:17+01:00"
LABEL edu.mit.cave.tester.image.version="0.1.0"
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint-alt.sh
ENTRYPOINT ["docker-entrypoint-alt.sh"]
