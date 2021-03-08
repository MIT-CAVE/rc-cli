#!/bin/sh
readonly BASE_DIR=$(dirname $0)
readonly OUTPUTS_DIR="$(dirname ${BASE_DIR})/data/model_apply_outputs"

echo "Reading Input Data"
sleep 1
echo "Solving Dark Matter Waveforms"
sleep 1
echo "Quantum Computer is Overheating"
sleep 1
echo "Trying Alternate Measurement Cycles"
sleep 1
echo "Found a Great Solution!"
sleep 1
echo "Checking Validity"
sleep 1
echo "The Answer is 42!"
sleep 1

# Remove any old solution if it exists
rm -rf ${OUTPUTS_DIR}/predicted_routes.json 2> /dev/null

echo "Executing a python script from the Shell Script to actually solve the problem"
python3 src/model_apply.py \
  && echo "Success: The '${OUTPUTS_DIR}/predicted_routes.json' file has been saved" \
  || echo "Failure: Something did not quite work correct when executing the Python script!"
if [ ! -f "${OUTPUTS_DIR}/predicted_routes.json" ]; then
  exit 1
fi
echo "Done!"
