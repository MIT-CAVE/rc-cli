# `arc-hello` app
## Introduction
This document describes the minimal requirements for your application and the basic commands that you will use to build, run, debug (optional), and save your solution to a Docker image file.

The current "Hello world!" app in this directory matches the requirements and will help you practice setting up a working example or serve as a template for your own solution.

Please note that after saving the Docker image, all participants are strongly encouraged to validate their solutions [via the trainer](../../README.md) before submitting the Docker image files through the platform.

## Project structure
Regardless of the programming language(s) or libraries you use for your application, the following directories and files must be present in your solution:
```
├── data
│   ├── inputs
│   │   └── <input-file(s)>
│   └── outputs
├── Dockerfile
└── run.sh
```

<details>
<summary>A Python-based project structure</summary>

```
├── data
│   ├── inputs
│   │   └── <input-file(s)>
│   └── outputs
├── src
│   └── main.py
├── .dockerignore
├── Dockerfile
├── requirements.txt
└── run.sh
```
</details>

## Setup
The following commands refer to the `arc-hello` application, but apart from the name of the Docker image, the syntax should remain exactly the same for your solution.

Please refer to your platform and choose the right path for you:
### Windows Command Line (`cmd`)
<details>
<summary>Details</summary>

#### Build
```sh
docker build -t arc-hello .
```

#### Run
```sh
docker run --rm ^
  -v "%cd%\data\inputs":/home/arc/data/inputs:ro ^
  -v "%cd%\data\outputs":/home/arc/data/outputs ^
  arc-hello
```

#### Debug (optional)
If there are any issues with your setup or if you want to debug your application inside the container, you can run the following command to enable an interactive shell at runtime:
```sh
docker run --rm --entrypoint="" ^
  -v "%cd%\data\inputs":/home/arc/data/inputs:ro ^
  -v "%cd%\data\outputs":/home/arc/data/outputs ^
  arc-hello
```  
> The default `ENTRYPOINT` has been intentionally overridden by an empty value to prevent the automatic execution of the `run.sh` script.

#### Save
Once you have a valid solution, you can save your Docker image to the standard location that will be fetched by the trainer:
```sh
docker save --output ..\..\solutions\arc-hello.tar arc-hello
```
<!-- Although `tar` files are completely valid for submissions, you can follow [these instructions](https://stackoverflow.com/a/36733177) if you want to use the gzip compression utility. Then you can run the following alternative command:
```sh
docker save arc-hello | gzip > ..\..\solutions\arc-hello.tar.gz # review
``` -->
</details>

### Windows (PowerShell) / Mac / Linux
<details>
<summary>Details</summary>

#### Build
```sh
docker build -t arc-hello .
```

#### Run
```sh
docker run --rm \
  -v "$(pwd)"/data/inputs:/home/arc/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/home/arc/data/outputs \
  arc-hello
```

#### Debug (optional)
If there are any issues with your setup or if you want to debug your application inside the container, you can run the following command to enable an interactive shell at runtime:
```sh
docker run --rm --entrypoint="" \
  -v "$(pwd)"/data/inputs:/home/arc/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/home/arc/data/outputs \
  -it arc-hello sh
```
> The default `ENTRYPOINT` has been intentionally overridden by an empty value to prevent the automatic execution of the `run.sh` script.

#### Save
Once you have a valid solution, you can save your Docker image to the standard location that will be fetched by the trainer:
```sh
docker save --output ../../solutions/arc-hello.tar.gz arc-hello
```

Alternatively, you can use the `gzip` compression utility to get a better compression ratio:
```sh
docker save arc-hello | gzip > ../../solutions/arc-hello.tar.gz
```
</details>
