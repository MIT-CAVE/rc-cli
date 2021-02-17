# App
## Introduction
This document describes the minimal requirements for your application and the basic commands that you will use to build, run, debug (optional), and save your solution to a Docker image file.

The `rc-python` app in this directory matches the requirements and will help you practice setting up a working example or serve as the template for your own solution.

Please note that after saving the Docker image, all participants are strongly encouraged to validate their solutions [via the trainer](../README.md) before submitting the Docker image files through the platform.

## Project structure
Regardless of the programming language(s) or libraries you use for your application, the following directories and files must be present in your solution:
```
├── data
│   ├── evaluate_inputs
│   │   └── <evaluate-input-file(s)>
│   ├── evaluate_outputs
│   ├── setup_inputs
│   │   └── <setup-input-file(s)>
│   └── setup_outputs
├── src
│   └── <source-code-file(s)-or-dir(s)>
├── Dockerfile
├── evaluate.sh
└── setup.sh
```

<details>
<summary>A Python-based project structure</summary>

```
├── data
│   ├── evaluate_inputs
│   │   └── <evaluate-input-file(s)>
│   ├── evaluate_outputs
│   ├── setup_inputs
│   │   └── <setup-input-file(s)>
│   └── setup_outputs
├── src
│   └── main.py
├── .dockerignore
├── Dockerfile
├── evaluate.sh
├── requirements.txt
└── setup.sh
```
</details>

## Solutions
The `solutions` directory helps participants to organize and save their Docker images to be validated by the RC Tester. All files under this directory will be ignored by the Git repository.

## Setup
The following commands refer to the `rc-python` application, but apart from the name of the Docker image, the syntax should remain exactly the same for your solution.

Please refer to your platform and choose the right path for you:
### Windows Command Line (`cmd`)
<details>
<summary>Details</summary>

#### Build
```sh
docker build -t rc-python .
```

#### Run
```sh
docker run --rm ^
  -v "%cd%\data\inputs":/home/app/data/inputs:ro ^
  -v "%cd%\data\outputs":/home/app/data/outputs ^
  rc-python
```

#### Debug (optional)
If there are any issues with your setup or if you want to debug your application inside the container, you can run the following command to enable an interactive shell at runtime:
```sh
docker run --rm --entrypoint="" ^
  -v "%cd%\data\inputs":/home/app/data/inputs:ro ^
  -v "%cd%\data\outputs":/home/app/data/outputs ^
  rc-python
```  
> The default `ENTRYPOINT` has been intentionally overridden by an empty value to prevent the automatic execution of the `run.sh` script.

#### Save
Once you have a valid solution, you can save your Docker image to the standard location that will be fetched by the trainer:
```sh
docker save --output ..\..\solutions\rc-python.tar rc-python
```
<!-- Although `tar` files are completely valid for submissions, you can follow [these instructions](https://stackoverflow.com/a/36733177) if you want to use the `gzip` compression utility. Then you can run the following alternative command:
```sh
docker save rc-python | gzip > ..\..\solutions\rc-python.tar.gz # review
``` -->
</details>

### Windows (PowerShell) / Mac / Linux
<details>
<summary>Details</summary>

#### Build
```sh
docker build -t rc-python .
```

#### Run
```sh
docker run --rm \
  -v "$(pwd)"/data/inputs:/home/app/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/home/app/data/outputs \
  rc-python
```

#### Debug (optional)
If there are any issues with your setup or if you want to debug your application inside the container, you can run the following command to enable an interactive shell at runtime:
```sh
docker run --rm --entrypoint="" \
  -v "$(pwd)"/data/inputs:/home/app/data/inputs:ro \
  -v "$(pwd)"/data/outputs:/home/app/data/outputs \
  -it rc-python sh
```
> The default `ENTRYPOINT` has been intentionally overridden by an empty value to prevent the automatic execution of the `run.sh` script.

#### Save
Once you have a valid solution, you can save your Docker image to the standard location that will be fetched by the trainer:
```sh
docker save --output ../../solutions/rc-python.tar.gz rc-python
```

Alternatively, you can use the `gzip` compression utility to get a better compression ratio:
```sh
docker save rc-python | gzip > ../../solutions/rc-python.tar.gz
```
</details>
