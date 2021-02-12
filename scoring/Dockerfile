# syntax = docker/dockerfile:1.2
ARG PYTHON_VERSION=3.9.1
ARG SOURCE_DIR=/home/scoring/

# builder image
FROM python:${PYTHON_VERSION}-alpine as builder
COPY ./requirements.txt ./
# install Python dependencies to the local user directory
RUN pip install --user --requirement ./requirements.txt

FROM python:${PYTHON_VERSION}-alpine
LABEL edu.mit.cave.scoring.image.vendor="MIT CTL Computational and Visual Education Lab"
LABEL edu.mit.cave.scoring.image.authors="Connor Makowski <conmak@mit.edu>, Luis Vasquez <luisvasq@mit.edu>, Willem Guter <wjguter@mit.edu>"
LABEL edu.mit.cave.scoring.image.title="Routing Challenge Scoring"
LABEL edu.mit.cave.scoring.image.licenses="Copyright (c) 2021 MIT CTL CAVE Lab"
LABEL edu.mit.cave.scoring.image.created="2021-02-11 22:21:05"
LABEL edu.mit.cave.scoring.image.version="0.1.0"
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
RUN addgroup -g 1000 scoring && adduser -u 1000 -G scoring -s /bin/sh -D scoring
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
COPY --from=builder --chown=scoring:scoring /root/.local/ ./.local/
COPY --chown=app:app ./main.py ./
COPY --chown=scoring:scoring docker-entrypoint.sh /usr/local/bin/
USER scoring
ENTRYPOINT ["docker-entrypoint.sh"]
