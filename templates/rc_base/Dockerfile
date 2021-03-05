# syntax = docker/dockerfile:1.2
ARG UBUNTU_RELEASE=20.04
ARG SOURCE_DIR=/home/app/

FROM ubuntu:$UBUNTU_RELEASE
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
RUN groupadd --gid 1000 app \
 && useradd --uid 1000 --gid app --shell /bin/bash --create-home app \
 # install pkgs
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # you might need build-essential
    build-essential \
    python3 \
    # other pkgs...
 && rm -rf /var/lib/apt/lists/*
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./src/ ./src/
USER app
CMD ["/bin/bash"]
