# RC CLI
## Introduction
This repository houses all code needed to setup, evaluate and test code for the Amazon Routing Challenge.

Using the `rc-cli`, participants of the Amazon Routing Challenge will be able to:
- Create a new app
- Run local development code with competition data
- Run environment agnostic code with competition data
- Save solution files (a file that can be submitted for evaluation)
- Test local code and solutions with the official scoring algorithm

Saved solutions that have been tested can be uploaded to the competition site: [routingchallenge.io](https://routingchallenge.io)

## Mac and Unix Setup
1. Install [Docker](https://docs.docker.com/get-docker/):
  - Note: Make sure to install Docker Engine v18.09 or later
  - If you have an older version of Docker, make sure [BuildKits are enabled](https://docs.docker.com/develop/develop-images/build_enhancements/#to-enable-buildkit-builds)
  - On Linux based systems you may need to follow the post installation setup instructions for docker:
    - `sudo groupadd docker`
    - `sudo usermod -aG docker $USER`
    - Validate the Installation
      - `docker run hello-world`

2. Install [Git](https://git-scm.com)
  - It is likely `git` is already installed. You can check with:
    ```
    git --version
    ```

3. Install the `rc-cli`
  - Run the following commands to install the `rc-cli`
    ```
    bash <(curl -s https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh) \
    https://cave-competition-app-data.s3.amazonaws.com/amzn_2021/data.tar.xz
    ```
    - Follow the prompts to finish the installation process
    - Note: If your computer does not support the needed version of `tar`, you can always use the zip data folder (about 50% larger data download)
      ```
      bash <(curl -s https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh) \
      https://cave-competition-app-data.s3.amazonaws.com/amzn_2021/data.zip
      ```

4. Validate the installation was successful
  - Run the following command:
    ```
    rc-cli version
    ```
  - If successful, the output should look something like:
    ```
    Routing Challenge CLI 0.1.3
    ```
  - If unsuccessful, you may get something like:
    ```
    rc-cli: command not found
    ```

5. Continue to the [Create Your App section](#create-your-app) below

## Windows 10 Setup
1. Install [Docker](https://hub.docker.com/editions/community/docker-ce-desktop-windows/)
  - Install WSL2 update during Docker installation
    - Update your WSL2 Kernel (If you are prompted during installation)
      - Click on link to the Windows Documentation about WSL2
      - Download the file to update the WSL kernel package to WSL2
      - Use the downloaded package to install the WSL2 Kernel
  - Reboot your system

2. Open **PowerShell** as **Administrator**
  - In PowerShell type:
    ```
    wsl --set-default-version 2
    ```
  - Press `Enter`
  - Exit PowerShell

3. Install Ubuntu 20.04
  - In the Microsoft store, search for `Ubuntu 20.04`
  - Install the Ubuntu 20.04 App

4. Open the `Ubuntu 20.04` app
  - This may take a while the first time
  - You will be prompted for a username and password
    - Set your username and password
    - **MAKE SURE TO REMEMBER THESE**
  - Close the app

5. Open the Docker Desktop app
  - In settings > resources > WSL Integration
    - Allow Ubuntu 20.04
  - Reboot Docker

6. Open the `Ubuntu 20.04` app
  - Run the following commands to finish setting up Docker:
    - Note: You may be prompted for your password
      - This is your Ubuntu password
    ```
    sudo groupadd docker
    ```
    ```
    sudo usermod -aG docker $USER
    ```
  - Validate Docker is working with the following command:
    ```
    docker run hello-world
    ```
    - This may not work until you close and re-open Docker.

7. Install the `rc-cli` in the `Ubuntu 20.04` app
  - Run the following commands to install the `rc-cli`
    ```
    bash <(curl -s https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh) \
    https://cave-competition-app-data.s3.amazonaws.com/amzn_2021/data.tar.xz
    ```
    - Follow the prompts to finish the installation process

8. Validate the installation was successful in the `Ubuntu 20.04` app
  - Run the following command:
    ```
    rc-cli version
    ```

9. Continue to the [Create Your App section](#create-your-app) below

## Create Your App
1. Get available commands
  ```
  rc-cli help
  ```

2. Create an app in your current directory
  - Note: Feel free to change `my-app` to any name you want
  ```
  rc-cli new-app my-app
  ```

3. Enter the app directory
  ```
  cd my-app
  ```

4. Get the folder location on your machine to open the app in your favorite editor.
  - On Mac:
    - Open your current directory in finder
      ```
      open .
      ```
    - Display your current directory as a path
      ```
      echo $PWD
      ```
  - On Linux:
    - Display your current directory as a path
      ```
      echo $PWD
      ```
  - On Windows 10 (using WSL Ubuntu 20.04)
    - Open explorer from your current directory
      ```
      explorer.exe .
      ```
    - Alternatively, your `Ubuntu 20.04` app stores files on your local operating system at:
      - `\\wsl$`>`Ubuntu-20.04`>`home`>`your-username`

5. All `rc-cli` commands and usages are documented in your created application as `README.md`
