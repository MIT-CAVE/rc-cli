# syntax = docker/dockerfile:1.2
ARG PYTHON_VERSION=3.9.1
ARG SOURCE_DIR=/home/app/

# builder image
FROM python:${PYTHON_VERSION}-alpine as builder
COPY ./requirements.txt ./
# install Python dependencies to the local user directory
RUN pip install --user --requirement ./requirements.txt

FROM python:${PYTHON_VERSION}-alpine
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /bin/sh -D app
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
COPY --from=builder --chown=app:app /root/.local/ ./.local/
COPY --chown=app:app ./src/ ./src/
COPY --chown=app:app ./*.sh ./
USER app
CMD ["/bin/sh"]
