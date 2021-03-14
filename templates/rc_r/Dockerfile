# syntax = docker/dockerfile:1.2
ARG R_BASE_VERSION=4.0.4
ARG SOURCE_DIR=/home/app/

# install pkgs
# RUN apt update \
# && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
#  # Packages here \
# && rm -rf /var/lib/apt/lists/*
RUN Rscript -e "install.packages(\"versions\")"
COPY ./requirements.txt ./
# install R dependencies from requirements.txt file
RUN while IFS=" " read -r package version; do \
      Rscript -e "versions::install.versions(c('$package'), c('$version'))"; \
    done < "requirements.txt"

ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN mkdir -p $SOURCE_DIR
WORKDIR $SOURCE_DIR
RUN deluser --quiet --remove-all-files docker \
 && groupadd --gid 1000 app \
 && useradd --uid 1000 --gid app --shell /bin/bash --create-home app
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./src/ ./src/
USER app
CMD ["/bin/bash"]
