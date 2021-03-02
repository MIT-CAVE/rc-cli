# syntax = docker/dockerfile:1.2
ARG R_BASE_VERSION=4.0.4
ARG SOURCE_DIR=/home/app/

FROM r-base:$R_BASE_VERSION
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
RUN groupadd --gid 1001 app \
 && useradd --uid 1001 --gid app --shell /bin/bash --create-home app \
# install pkgs
 && apt update \
# R devtools
 && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*
# install R dependencies from requirements.txt file
RUN Rscript -e "install.packages('devtools')"
COPY ./requirements.txt ./
RUN while IFS=" " read -r package version; do \
      Rscript -e "devtools::install_version('"$package"', version='"${version}"')"; \
    done < "requirements.txt"
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./src/ ./src/
USER app
CMD ["/bin/bash"]
