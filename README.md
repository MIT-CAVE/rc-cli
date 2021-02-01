# Amazon Last Mile Routing Research Challenge
## Introduction
This repository serves for the setup of a computing environment where the participant solutions will be run and validated.

Thus, the participants of the Routing Challenge competition will have the opportunity to recreate the evaluation environment used by the contest staff, so that they can validate their results and adjust their proposals before making their final submissions.

The proposed solutions will be compiled into Docker image files (`.tar` or `.tar.gz`) and uploaded via the web platform.

## Setup
### Prerequisites
- Docker Engine v18.09 or later
- BuildKit builds [must be enabled](https://docs.docker.com/develop/develop-images/build_enhancements/#to-enable-buildkit-builds)

### App
[Build and save your solution in a Docker image file](examples/hello-rc/README.md).

### Routing Challenge Trainer
##### Build
```sh
docker build -t rctrain .
```

##### Run
###### Windows (PowerShell) / Mac / Linux
```sh
./rctrain <docker-image>
```
Where `<docker-image>` is the filename of the saved Docker image. The
`<docker-image>` name (without the extension) **must match the image tag** for which the solution was created and saved as a Docker image.

###### Windows Command Line (`cmd`)
Working on a `rctrain.cmd` CLI.
<!-- ```sh
docker run --privileged ^
  -v "%cd%\solutions":/solutions:ro ^
  -v "%cd%\data\inputs":/data/inputs:ro ^
  -v "%cd%\data\outputs":/data/outputs ^
  rctrain
``` -->
</details>

##### Debug
<details>
<summary>This section is not intended for users and should be left out of the document for the public repo.</summary>

```sh
docker run --privileged --rm --entrypoint="" -e IMAGE_NAME=<docker-image> \
  -v "$(pwd)"/solutions:/solutions:ro \
  -v "$(pwd)"/data/inputs:/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/data/outputs \
  -it rctrain sh
```
Once in the container, since the trainer's `ENTRYPOINT` has been overridden, the `dind`'s built-in `ENTRYPOINT` must be run manually:
```sh
/usr/local/bin/dockerd-entrypoint.sh dockerd &
```
</details>
