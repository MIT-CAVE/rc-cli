# `arc-hello-world` app

## UNIX

### Build
```sh
docker build -t arc-hello-world .
```

### Run
```sh
docker run --rm --name=arc-hello -v "$(pwd)"/data:/home/arc/data arc-hello-world
```
<!-- This would be the command that will be executed by a trainer instance:
```sh
docker run --rm --name=arc-hello -v in_data:/home/arc/data arc-hello-world
``` -->
<!-- TODO Once security has been determined, the input data will be available on a read-only volume:
```sh
docker run --rm --name=arc-hello -v in_data:/home/arc/data:ro arc-hello-world
```
-->

### Debug
```sh
docker run --rm --name=arc-hello --entrypoint="" -v "$(pwd)"/data:/home/arc/data -it arc-hello-world sh
```

## Mac

## Windows
