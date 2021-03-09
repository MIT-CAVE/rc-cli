# App
## Introduction
This document describes the RC-CLI application structure and the commands you will use to build, run, debug, validate, and save your dockerized solution to a file to submit at the [Amazon Routing Challenge](https://routingchallenge.io/).

The app in this directory matches the competition requirements and will help you practice setting up a working example or serve as the template for your solution.

Amazon has provided data containing historical route sequences from multiple delivery stations in North America.

This data include:
- Shipment-level information: delivery locations and physical shipment characteristics [`package_data.json`]
- Transit information: travel times [`travel_times.json`]
- Route-level information: date of route, route origin, and vehicle characteristics [`route_data.json` and `actual_sequences.json`]

## Using the Routing Challenge CLI
There are three phases of analysis:
- Model-Build
- Model-Apply
- Model-Score

A Docker image will run source code for each of these phases.
- The **Model-Build** phase will have access to historical data on known routes and output a model that can predict route sequences.
- The **Model-Apply** phase will apply that model to new data and predict route sequences. In effect, the model-apply puts the model built in the previous phase into production.
- The **Model-Score** phase will compare the proposed routes to actual sequences and provide a score.

After saving a snapshot of a working model, it can be submitted as a solution to the routing challenge. When being evaluated in the competition, your submission will run through the following steps:
1. Reset the data folder [`rc-cli reset-data`]
2. Build a model using provided training data [`rc-cli model-build`]
3. Apply your model to a new data set [`rc-cli model-apply`]
4. Score your model [`rc-cli model-score`]

Run all these steps on a saved model with a single command using `rc-cli production-test`. We discuss these steps and how they work below, but first, let us cover the file structure in the template application.

## Project Structures
Regardless of the programming language(s) or libraries you use for your application, the following directories and files must be present:

```
├── data
│   ├── model_build_inputs
│   │   └── <model-build-input-file(s)>
│   ├── model_build_outputs
│   ├── model_apply_inputs
│   │   └── <model-apply-input-file(s)>
│   └── model_apply_outputs
├── src
│   └── <source-code-file(s)-or-dir(s)>
├── Dockerfile
├── model_build.sh
└── model_apply.sh
```

When developing your model, you can run any code from the src/ directory and read from the data/ directory matching the phase you are executing. We suggest you develop your code in the src/ folder and use relative paths to reference the datasets in the data/ folders.

**NOTE:** The data/ directory will not be included as part of your submission. Clean data will be mounted using evaluation data that matches this structure during the submission scoring.

For additional details on Dockefile setup please refer to [custom_dev_stack.md](https://github.com/MIT-CAVE/rc-cli/blob/main/templates/custom_dev_stack.md) on GitHub.

To see a more detailed example file structure, expand the Python example below:
<details>
<summary>An example Python-based project structure</summary>

There are templates available for Python, a Unix shell, and R. See the "Bootstrap you Project" section of the [RC-CLI readme](https://github.com/MIT-CAVE/rc-cli/blob/main/README.md) for more information. This is an example file structure for a python-based solution.

When you create a `new-app`, the RC-CLI creates a Docker image. In this Python example, the Dockerfile installs packages from requirements.txt needed for your Dockerized python environment.

The `model_build.sh` and `model_apply.sh` scripts are called by the RC-CLI inside the Docker image and serve as the entry point to your code.

The folders listed below include additional folders used for logging, storing saved models, and scoring not required for submission. The `new-app` command creates these folders.
- `data/model_build_outputs` would contain a trained model created from the "build inputs" dataset.
- `data/model_apply_outputs` folder would contain the predicted routes based on your model and the "apply inputs" dataset.
- `data/model_score_inputs`,`data/model_score_outputs`, and `data/model_score_timings` directories are utilized by the RC-CLI when scoring your application and not necessary for submission. After scoring your model, find the results in `data/model_score_outputs/scores.json`.
- `snapshots` contains saved Docker images and their corresponding data files.
- `logs` contains folders created by the RC-CLI while running commands. Logs are kept for `configure-app`, `model-debug`, `save_snapshot`, etc...

```
├── data
│   ├── model_build_inputs
│   │   └── <provided build-input-file(s)>
│   ├── model_build_outputs
│   │   └── TensorFlow_model.pb
│   ├── model_apply_inputs
│   │   └── <provided apply-input-file(s)>
│   ├── model_apply_outputs
│   │   └── proposed_sequences.json
│   ├── model_score_inputs
│   │   └── <provided score-input-file(s)>
│   ├── model_score_outputs
│   │   └── scores.json
│   └── model_score_timings
│       ├── model_apply_time.json
│       └── model_build_time.json
├── src
│   ├── model_build.py
│   └── model_apply.py
├── snapshots
│   └── test_model
│       ├── data
│       └── test_model.tar.gz
├── logs
│   └── save_snapshot
│       └── test1_configure_2021-03-04T15:21:15:z.log
├── .dockerignore
├── Dockerfile
├── model_build.sh
├── model_apply.sh
└── requirements.txt
```
</details>


## Routing Challenge CLI Commands
General Usage:  rc-cli COMMAND [options]

The RC-CLI commands will be presented in the usual order for the phases of analysis. Additional commands will be covered at the end.

### new-app
```
rc-cli new-app [app-name] [template-name]
```
Create an application directory containing training data and an example Dockerfile. The following templates are available:
- rc_base: `Ubuntu 20.04` Docker image. It is a lightweight Unix version with a bash shell. Good option if you plan to customize your environment.
- rc_python: `Alpine` Docker image with Python 3.9.1 installed. The place to start if you are coding in Python.
- rc_r: `R 4.0.4` Docker image. A simple R example to get you started.

This command copies all of the data and creates a docker image. This process can take several minutes as both the dataset and the docker image are large files and creating an image takes time.

### configure-app
```
rc-cli configure-app
```
**NOTE:** Upon running `rc-cli new-app`, a default Docker image was created.

Configure your app's current Docker image using your local Dockerfile. Every time you update your project root (shell scripts, requirements, or Dockerfile), you should run `rc-cli configure-app` again. This overwrites the previous image giving you an updated image that your model will run in.

**Example:** To add necessary Python packages to your Docker image, use  `pip freeze` or  `conda list --export` to generate a list of requirements for your environment. Only install the packages needed for this script, not everything listed in your default environment. These commands will show you which package versions you need.

If running `pip freeze` lists `numpy==1.20.1`, add this version information to `requirements.txt` and use `rc-cli configure-app` to configure your Docker image. If you are using `conda list --export`, make sure you change the output to pip style formatting before updating `requirements.txt`.

### model-build
```
rc-cli model-build [snapshot-name]
```
Execute the model_build.sh script inside of your app's Docker image. During the `model-build` phase you will have access to the following data/ directories:
- `data/model_build_inputs` (read)
- `data/model_build_outputs` (read/write)

In `data/model_build_inputs`, you will have access to historical data of known routes. During this phase, you will use that data to create a model that can predict a proposed route sequence based on new data available in the `model_apply ` phase. You can save any models, graphs, variables, or data that you generated during this phase in `data/model_build_outputs` directory to be used in the `model-apply` phase.

If you have not saved a model using the snapshot command, the  `model-build` phase is run on the current directory.

### model-apply
```
rc-cli model-apply [snapshot-name]
```
Execute the model_apply.sh script inside of your app's Docker image. Run after the model-build phase.

During the `model-apply` phase you will have access to the following data/ directories:
- `data/model_build_outputs` (read)
- `data/model_apply_inputs` (read)
- `data/model_apply_outputs` (read/write)

You do not have access to the historical data at this phase, but there is a new dataset provided in `data/model_apply_inputs` that will be used by the model created in the `model-build` phase to generate predicted routes. The predicted routes should be saved in `data/model_apply_outputs/proposed_sequences.json`

###  model-score
```
model-score [snapshot-name]
```
Apply the scoring algorithm using `data/model_apply_output/proposed_sequences.json` created during the `model-apply` phase. The scoring algorithm compares your proposed route sequences against the actual sequences for the same set of stops. It outputs a numerical score that quantifies the proximity / similarity of both sequences. This algorithm will be the same one used when evaluating submissions at the end of the competition. The only difference will be the dataset provided during the `model-apply` phase.

### model-debug
```
rc-cli model-debug [snapshot-name]
```
Use this command to debug your current app. It will start the Docker image for your project. You can run shell scripts and execute files. You can test if your Docker image has the correct environment to run your source code. The `model-debug` command provides the following directory access:
- `data/model_build_inputs` (read/write)
- `data/model_build_outputs` (read/write)
- `data/model_apply_inputs` (read/write)
- `data/model_apply_outputs` (read/write)

### save-snapshot
```
rc-cli save-snapshot [snapshot-name]
```
Save the current app as a snapshot with the same name as your app or with a specified name. This command copies the current data into a folder that will be reference by this snapshot and saves a Docker image of your current app. Most commands can specify a snapshot to run.

To create a submission for this challenge, create a snapshot and upload the `[snapshot-name].tar.gz` to https://routingchallenge.io/. Please note that after saving the Docker image, all participants are strongly encouraged to validate their solutions using `rc-cli production-test [snapshot-name]` before submitting the Docker image files through the platform.

### production-test
```
rc-cli production-test [snapshot-name]
```
This command tests the complete scoring process on your app.
**WARNING:** This command resets your data directory. We recommend creating a snapshot and run this command against the snapshot.

The following commands are run in order:
1. `rc-cli reset-data` - Reset the data folder
2. `rc-cli model-build` - Build a model using provided training data
3. `rc-cli model-apply` - Apply your model to a new dataset
4. `rc-cli model-score`
 - Score your model against actual sequences for the stop data in the new dataset

### reset-data
```
rc-cli reset-data [snapshot-name]
```
This command resets all of the files in `data/`. Any files saved in the output , such as models or predicted sequences, will be lost.

### update
```
rc-cli update
```
This command pulls down the latest data and executables for RC-CLI. It also configures Docker images for testing and scoring.
