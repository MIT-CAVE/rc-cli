# syntax = docker/dockerfile:1.2
ARG PYTHON_VERSION=3.9.1
ARG SOURCE_DIR=/home/arc/
ARG MOUNT_DIR=/home/arc/data/

# builder image
FROM python:${PYTHON_VERSION}-alpine as builder
COPY ./requirements.txt ./
# install Python dependencies to the local user directory
RUN pip install --user --requirement ./requirements.txt

FROM python:${PYTHON_VERSION}-alpine
ARG MOUNT_DIR
ARG SOURCE_DIR
ENV MOUNT_DIR $MOUNT_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN addgroup -g 1000 arc && adduser -u 1000 -G arc -s /bin/sh -D arc
RUN mkdir -p $SOURCE_DIR && mkdir -p $MOUNT_DIR && chown arc:arc $MOUNT_DIR
WORKDIR $SOURCE_DIR
COPY --from=builder --chown=arc:arc /root/.local $SOURCE_DIR/.local
COPY --chown=arc:arc ./data $MOUNT_DIR
COPY --chown=arc:arc ./src ./src
COPY --chown=arc:arc ./run.sh ./
USER arc
VOLUME $MOUNT_DIR
ENTRYPOINT ["run.sh"]
