# Amazon Last Mile Routing | RESEARCH CHALLENGE
## Introduction
This repository serves for the setup of a computing environment where the participant solutions will be run and validated.

Thus, the participants of the Last Mile Routing Competition will have the opportunity to recreate the evaluation environment used by the contest staff, so that they can validate their results and adjust their proposals before making their final submissions.

The proposed solutions will be compiled into Docker image files (`.tar` or `.tar.gz`) and uploaded via the web platform.

## Setup
### Prerequisites
- Docker Engine v18.09 or later
- BuildKit builds [must be enabled](https://docs.docker.com/develop/develop-images/build_enhancements/#to-enable-buildkit-builds)

### App
[Build and save your solution in a Docker image file](examples/arc-hello/README.md).

### Trainer
Please refer to your platform and choose the right path for you:

#### Windows Command Line (`cmd`)
<details>
<summary>Details</summary>

##### Build
```sh
docker build --build-arg IMAGE_NAME=<docker-image> -t arc-trainer .
```
Where `<docker-image>` is the filename of the saved Docker image.
> Example:
```sh
docker build --build-arg IMAGE_NAME=arc-hello.tar -t arc-trainer .
```

###### Build-time variables
The build-time variables are specified via the `--build-arg` option:
<!--
There are several ARGs available to adjust the final image or match your preferences for your build process.

`DOCKER_VERSION`: Matches the version of Docker Engine (`<docker-version>`) on top of which the inner container will run.
- **Values**: `20.10` (default), `19.03`, ..., `18.09`.
> Full list of values [here](https://hub.docker.com/_/docker?tab=tags).

`IMAGE_BASE_DIR`: Sets the relative path of the directory containing the saved Docker images.
- **Values**: `solutions` (default).
-->

`IMAGE_NAME`: Sets the filename of the Docker image, including its extension (`.tar` or `.tar.gz`) found in the `solutions` directory.
**Values**: `arc-hello.tar` (default), `my-solution.tar.gz`, ...

Please note the `IMAGE_NAME` variable (without the extension) **must match the Docker image tag** for which the solution was created and saved as a Docker image file.

##### Run
```sh
docker run --privileged ^
  -v "%cd%\solutions":/solutions:ro ^
  -v "%cd%\data\inputs":/data/inputs:ro ^
  -v "%cd%\data\outputs":/data/outputs ^
  arc-trainer
```
</details>

#### Windows (PowerShell) / Mac / Linux
<details>
<summary>Details</summary>

##### Build
```sh
docker build --build-arg IMAGE_NAME=<docker-image> -t arc-trainer .
```
Where `<docker-image>` is the filename of the saved Docker image.
> Example:
```sh
docker build --build-arg IMAGE_NAME=arc-hello.tar -t arc-trainer .
```

###### Build-time variables
The build-time variables are specified via the `--build-arg` option:
<!--
There are several ARGs available to adjust the final image or match your preferences for your build process.

`DOCKER_VERSION`: Matches the version of Docker Engine (`<docker-version>`) on top of which the inner container will run.
- **Values**: `20.10` (default), `19.03`, ..., `18.09`.
> Full list of values [here](https://hub.docker.com/_/docker?tab=tags).

`IMAGE_BASE_DIR`: Sets the relative path of the directory containing the saved Docker images.
- **Values**: `solutions` (default).
-->

`IMAGE_NAME`: Sets the filename of the Docker image, including its extension (`.tar` or `.tar.gz`) found in the `solutions` directory.
**Values**: `arc-hello.tar` (default), `my-solution.tar.gz`, ...

Please note the `IMAGE_NAME` variable (without the extension) **must match the Docker image tag** for which the solution was created and saved as a Docker image file.

##### Run
```sh
docker run --privileged --rm \
  -v "$(pwd)"/solutions:/solutions:ro \
  -v "$(pwd)"/data/inputs:/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/data/outputs \
  arc-trainer
```
</details>

#### Debug
<details>
<summary>This section is not intended for users and should be left out of the document for the public repo.</summary>

```sh
docker run --privileged --rm --entrypoint="" \
  -v "$(pwd)"/solutions:/solutions:ro \
  -v "$(pwd)"/data/inputs:/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/data/outputs \
  -it arc-trainer sh
```
Once in the container, since the trainer's `ENTRYPOINT` has been overridden, the `dind`'s built-in `ENTRYPOINT` must be run manually:
```sh
/usr/local/bin/dockerd-entrypoint.sh dockerd &
```
</details>
