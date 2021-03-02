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

# Copy in example output as the output for this algorithm
rm -rf ${OUTPUTS_DIR}/output.json 2> /dev/null
cp ${OUTPUTS_DIR}/example_output.json ${OUTPUTS_DIR}/output.json
if [ ! -f "${OUTPUTS_DIR}/example_output.json" ]; then
  exit 1
fi
echo "Success: The '${OUTPUTS_DIR}/output.json' file has been saved"
echo "Done!"
