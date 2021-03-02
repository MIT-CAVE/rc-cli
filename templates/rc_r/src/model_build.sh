#!/bin/sh
readonly BASE_DIR=$(dirname $0)
readonly OUT_FILE="$(dirname ${BASE_DIR})/data/model_build_outputs/model.json"

echo "Initializing Quark Reducer"
sleep 1
echo "Placing Nano Tubes In Gravitational Wavepool"
sleep 1
echo "Measuring Particle Deviations"
sleep 1
echo "Programming Artificial Noggins"
sleep 1
echo "Beaming in Complex Materials"
sleep 1
echo "Solving Model"
sleep 1
echo "Saving Solved Model State"
sleep 1

echo '{
  "Model": "Hello from the model_build.py script!",
  "sort_by": "lat",
}' > ${OUT_FILE}
echo "Success: The '${OUT_FILE}' file has been saved"
