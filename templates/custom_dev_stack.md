# Dockerfile setup
## Introduction
Although we provide [Python](https://www.python.org/) and [R](https://www.r-project.org/) templates, teams can choose any programming languages and create their own custom app template.

This document will help you to correctly set up a functional custom app template.

## Initial setup
1. Make sure the [rc-cli](https://github.com/mit-cave/rc-cli) is installed locally on your system
  - You can check with:
    ```
    rc-cli --version
    ```

2. Folder structure is very important when using the `rc-cli`
  - To get started on any custom template, you should bootstrap a base template
  - This includes some starter code as well as all the necessary files and folder structures to properly set up your template
  - You can boostrap a new (and fully functional) app named `my-app` in your current directory using the `rc_base` template by running:
    ```
    rc-cli new-app my-app rc_base
    ```
  - You should now be ready to begin setting up your development stack with a `Dockerfile`

## Custom Development Stack Using Docker
Please follow these guidelines to ensure the `rc-cli` will work with your development stack as you setup your `Dockerfile`:

1. Select an appropriate Docker image(s) for your desired development stack
  - A good place to start looking is [Docker Hub](https://hub.docker.com/search?q=&type=image&category=languages)
  - Note: If your development stack does not have much Docker support or if you prefer to create a custom image for your environment, you may want to extend the Ubuntu based `Dockerfile` in the `rc_base` template.

2. In order for your `Dockerfile` to work with the `rc-cli`, it should meet the following minimum requirements:
  - Create an `app` user and `app` group for the container
  - Create a `/home/app/` directory
  - The directory `src` along with the `model_build.sh` and `model_apply.sh` script files in your template must be copied to `/home/app/`
    - `model_build.sh` and `model_apply.sh` should both be executable by the file owners
      - This should be set on your local OS before configuring your app image
      - You can do this on most unix systems with: `sudo chmod 755 model_build.sh & sudo chmod 755 model_apply.sh`
    - `model_build.sh` and `model_apply.sh` should both be owned by the Docker `app` user
      - This can happen in the Dockerfile when executing a `copy` command
  - The `/home/app/` directory must be included in the `PATH` environment variable, i.e. `/home/app/` must be part of the list of executable directories
    - This allows `rc-cli` to execute the `model_build.sh` and `model_apply.sh` files from anywhere
  - The default `USER` for your Docker image must be `app`
  - You should not define an `ENTRYPOINT` instruction within your custom Dockerfile
    - This will be overwritten by `rc-cli` to run the `model_build.sh` and `model_apply.sh` scripts
    - Instead, add any shell commands that you want to execute at run-time to the relevant `sh` files
  - Place a `CMD` instruction at the end of the Dockerfile to run the default shell of the image, e.g. `CMD ["/bin/bash"]` or `CMD ["/bin/sh"]`
  - Only the `src` directory, `model_build.sh` and `model_apply.sh` should be copied in your `Dockerfile`:
    - Code in your `src` directory can pull data from the relative app `data` directory path during local development and `rc-cli` testing
      - During local development:
        - You will have unrestricted access to the `data` directory as you will be executing code locally
      - During `rc-cli` development (`model-build`, `model-apply`, `model-debug`)
        - The `rc-cli` will mount the needed data for each command from your local `data` folder as they exist at run time
          - Changes to this data during run time will be reflected in your local `data` folder
        - Data is restricted to the current phase
          1. `model-build`:
            - `data/model_build_inputs` (read)
            - `data/model_build_outputs` (read/write)
          2. `model-apply`:
            - `data/model_build_outputs` (read)
            - `data/model_apply_inputs` (read)
            - `data/model_apply_outputs` (read/write)
          - `model-debug`:
            - `data/model_build_inputs` (read/write)
            - `data/model_build_outputs` (read/write)
            - `data/model_apply_inputs` (read/write)
            - `data/model_apply_outputs` (read/write)
      - During `rc-cli` production testing (`production-test`)
        - The `rc-cli` will first reset your local `data` folder to the initial data state
          - This is exactly how the data will be formatted during official scoring
          - This will remove any local changes you have made in the `data` folder
          - Remember that none of your local data will ever get sent for scoring
            - If you want to manipulate the data, you need to adjust this data accordingly during the `model-build` and `model-apply` phases
        - The `rc-cli` will then mount the data for each command from your local `data` folder at run time
      - During the official scoring:
        - The `rc-cli` will mount different evaluation data in the exact same manner as production testing
          - This data will be the exact same structure

3. Once you have finished setting up or make any changes to your `Dockerfile` or `*.sh` scripts:
  - Run `configure-app`
    `rc-cli configure-app`
  - The output Docker logs can be found at:
    `logs/configure_app/`


## Example
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

## References
- If you need more information about the syntax of **Dockerfile**, check the [official documentation](https://docs.docker.com/engine/reference/builder/)
- [Best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) for writing Dockerfiles
