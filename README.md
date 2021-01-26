# Amazon Research Challenge 2021 - Docker
## Introduction
<TODO>

### Setup
#### Build
```sh
docker build -t arc-trainer:2021-0.1 .
```
#### Run
```sh
docker run -d -v in_data:/data:ro arc-trainer:2021-0.1
```
#### Debug
```sh
docker run --rm --entrypoint="" -v in_data:/data:ro -it arc-trainer:2021-0.1 sh
```
<!-- ### Instructions These guidelines are intended for the competitors and should be moved to the public repository of the competition when the platform is up.

Each folder contains a Dockerfile designed for a specific challenge. However, if you want to submit your own version of the Dockerfile or in case you want to match a particular setup, please refer to [these instructions]() to comply with the configuration expected by the Algorithm Data Trainer on the ARC server. -->
