# syntax = docker/dockerfile:1.2
ARG PYTHON_VERSION=3.9.1
ARG SOURCE_DIR=/home/app/

# builder image
FROM python:${PYTHON_VERSION}-alpine as builder
RUN apk update && apk --no-cache add \
# adding deps required by some popular Python packages
    g++
COPY ./requirements.txt ./
# install Python dependencies to the local user directory
RUN pip install --user --requirement ./requirements.txt

FROM python:${PYTHON_VERSION}-alpine
LABEL edu.mit.cave.scoring.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.scoring.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.scoring.image.title="Routing Challenge Scoring"
LABEL edu.mit.cave.scoring.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.scoring.image.created="2021-02-26 16:05:11-05:00"
LABEL edu.mit.cave.scoring.image.version="0.1.0"
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /bin/sh -D app
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
COPY --from=builder --chown=app:app /root/.local/ ./.local/
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./*.py ./
USER app
ENTRYPOINT ["docker-entrypoint.sh"]
