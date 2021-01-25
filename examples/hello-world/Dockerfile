# syntax = docker/dockerfile:1.2
ARG PYTHON_VERSION=3.9.1
ARG SOURCE_DIR=/home/hello/
ARG MOUNT_DIR=/data/

# builder image
FROM python:${PYTHON_VERSION}-alpine as builder
COPY ./requirements.txt ./
# install Python dependencies to the local user directory
RUN pip install --user --requirement ./requirements.txt

FROM python:${PYTHON_VERSION}-alpine
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
RUN addgroup -g 1000 hello && adduser -u 1000 -G hello -s /bin/sh -D hello
COPY --from=builder --chown=hello:hello /root/.local $SOURCE_DIR/.local
COPY --chown=hello:hello ./src ./src
COPY --chown=hello:hello ./run.sh ./
USER hello
ENTRYPOINT ["run.sh"]
EXPOSE 4000
