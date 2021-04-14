# syntax = docker/dockerfile:1.2
ARG PYTHON_VERSION=3.9.1
ARG SOURCE_DIR=/home/app/

FROM python:${PYTHON_VERSION}-alpine
RUN apk update && apk --no-cache add \
# adding deps required by some popular Python packages
    g++
COPY ./requirements.txt ./
# install Python dependencies to the local user directory
RUN pip install --user --requirement ./requirements.txt

ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /bin/sh -D app
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./src/ ./src/
USER app
CMD ["/bin/sh"]
