# What is this directory for?

The current directory serves as a mount point for Docker to allow the participants' Docker images to be validated by the `arc-trainer` instance. The participants should be encouraged to save their Docker image solutions in this folder and validate them through the `trainer`, before submitting their saved images through the web platform.

All files in this directory must be ignored by the Git repository, except for this README file (see [.gitignore](.gitignore)).

The directory and its files will be mounted as a [read-only bind mount](https://docs.docker.com/storage/bind-mounts/#use-a-read-only-bind-mount), at the Docker run-time stage.
