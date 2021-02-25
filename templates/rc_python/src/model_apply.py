from os import path
import sys, json, time

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
MODEL_BUILD_OUTPUTS_DIR = path.join(DATA_DIR, 'model_build_outputs')
MODEL_APPLY_INPUTS_DIR = path.join(DATA_DIR, 'model_apply_inputs')
MODEL_APPLY_OUTPUTS_DIR = path.join(DATA_DIR, 'model_apply_outputs')

# I/O Files
MODEL_BUILD_OUTPUT_FILEPATH = path.join(MODEL_BUILD_OUTPUTS_DIR, 'build_output.json')
PREDICTION_ROUTES_FILEPATH = path.join(MODEL_APPLY_INPUTS_DIR, 'prediction_routes.json')
MODEL_APPLY_OUTPUT_FILEPATH = path.join(MODEL_APPLY_OUTPUTS_DIR, 'example_output.json')

# Read input data
print('Reading Input Data')
# Model Build output
model_build_out = None
try:
    with open(MODEL_BUILD_OUTPUT_FILEPATH, newline='') as in_file:
        model_build_out = json.load(in_file)
except FileNotFoundError:
    print("The '{}' file is missing!".format(MODEL_BUILD_OUTPUT_FILEPATH))
except JSONDecodeError:
    print("Error in the '{}' JSON data!".format(MODEL_BUILD_OUTPUT_FILEPATH))
except Exception as e:
    print("Error when reading the '{}' file!".format(MODEL_BUILD_OUTPUT_FILEPATH))
    print(e)
# Prediction Routes (Model Apply input)
prediction_routes = None
try:
    with open(PREDICTION_ROUTES_FILEPATH, newline='') as in_file:
        prediction_routes = json.load(in_file)
except FileNotFoundError:
    print("The '{}' file is missing!".format(PREDICTION_ROUTES_FILEPATH))
except JSONDecodeError:
    print("Error in the '{}' JSON data!".format(PREDICTION_ROUTES_FILEPATH))
except Exception as e:
    print("Error when reading the '{}' file!".format(PREDICTION_ROUTES_FILEPATH))
    print(e)

if model_build_out and prediction_routes:
    print('Printing Input Data')
    print('model from model_build_out:', model_build_out)
    print('data for prediction_routes:', prediction_routes)
    time.sleep(1)
    # Solve for life the universe and everything
    print('{} Algorithm'.format(model_build_out.get("Algorithm","No Provided")))
    time.sleep(1)
    print('Solving Dark Matter Waveforms')
    time.sleep(1)
    print('Quantum Computer is Overheating')
    time.sleep(1)
    print('Trying Alternate Measurement Cycles')
    time.sleep(1)
    print('Found a Great Solution!')
    time.sleep(1)
    print('Checking Validity')
    time.sleep(1)
    print('The Answer is 42!')
    output={
        'Message':'Hello from the evaluation script!',
        'The_Answer_To_Life':42
    }

    # Write output data
    with open(MODEL_APPLY_OUTPUT_FILEPATH, 'w') as out_file:
        json.dump(output, out_file)
        print("Evaluate: The '{}' file has been saved".format(
            MODEL_APPLY_OUTPUT_FILEPATH
        ))
