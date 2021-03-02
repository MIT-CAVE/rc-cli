# Dockerfile setup
## Introduction
Although [Python](https://www.python.org/) and [R](https://www.r-project.org/) cover most programming language preferences, some teams can choose other programming languages and create their own `Dockerfile`s to set up their custom templates. This document will help you to quickly set up a working `Dockerfile`.

## `Dockerfile` and `rc-cli`
Please follow these guidelines to allow for a working environment between `Dockerfile` and `rc-cli`:

1. Select the base image(s) for your custom Dockerfile from a reputable Docker repository. Your best option should be [Docker Hub](https://hub.docker.com/search?q=&type=image&category=languages).
> If your programming language does not appear in the official images or if you prefer to create a custom image for your environment, you may want to extend the Ubuntu-based `Dockerfile` in the `rc_base` template.

2. Once you have selected the base image(s), in order for your Dockerfile to work with `rc-cli`, it should meet the following minimum requirements:
  - Create an `app` user and `app` group for the container
  - Create the `/home/app/` directory
  - The directory `src` along with the `model_build.sh` and `model_apply.sh` script files need to be copied to `/home/app/`
  - The `/home/app/` directory must be included in the `PATH` environment variable, i.e. `/home/app/` must be part of the list of executable directories. The reason for this is that `rc-cli` can execute the `model_build.sh` and `model_apply.sh` files.
  - The default `USER` for your Docker image must be `app`
  - You should not define an `ENTRYPOINT` instruction within your custom Dockerfile, as this will be overwritten by `rc-cli` to run the `model_build.sh` and `model_apply.sh` scripts. Instead, add any shell commands that you want to execute at run-time to these script files.
  - Place a `CMD` instruction at the end of the Dockerfile to run the default shell of the image, e.g. `CMD ["/bin/bash"]` or `CMD ["/bin/sh"]`

## Examples:
### Linux-based image with a Bash shell
<details>
<summary>Dockerfile</summary>

```Dockerfile
# syntax = docker/dockerfile:1.2
ARG SOURCE_DIR=/home/app/
# base image - replace <base-image>:<base-image-tag> with your values
FROM <base-image>:<base-image-tag>
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN mkdir -p $SOURCE_DIR
RUN groupadd --gid 1000 app \
 && useradd --uid 1000 --gid app --shell /bin/bash --create-home app
WORKDIR $SOURCE_DIR
# TODO: install dependencies (optional)
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./src/ ./src/
USER app
CMD ["/bin/bash"]
```
</details>

### Linux-based image with an Almquist shell
<details>
<summary>Dockerfile</summary>

```Dockerfile
# syntax = docker/dockerfile:1.2
ARG SOURCE_DIR=/home/app/
# base image - replace <base-image>:<base-image-tag> with your values
FROM <base-image>:<base-image-tag>
ARG SOURCE_DIR
ENV SOURCE_DIR $SOURCE_DIR
ENV PATH $PATH:$SOURCE_DIR
RUN mkdir -p $SOURCE_DIR
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /bin/sh -D app
WORKDIR $SOURCE_DIR
# TODO: install dependencies (optional)
COPY --chown=app:app ./*.sh ./
COPY --chown=app:app ./src/ ./src/
USER app
CMD ["/bin/sh"]
```
</details>

## References
- If you need more information about the syntax of **Dockerfile**, check the [official Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) for writing Dockerfiles
