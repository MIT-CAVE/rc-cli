from os import path
import sys, json, time

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
MODEL_BUILD_INPUTS_DIR = path.join(DATA_DIR, 'model_build_inputs')
MODEL_BUILD_OUTPUTS_DIR = path.join(DATA_DIR, 'model_build_outputs')

# I/O Files
ACTUAL_ROUTES_FILEPATH = path.join(MODEL_BUILD_INPUTS_DIR, 'actual_routes.json')
MODEL_BUILD_OUTPUT_FILEPATH = path.join(MODEL_BUILD_OUTPUTS_DIR, 'build_output.json')

# Read input data
print('Reading Input Data')
actual_routes = None
try:
    with open(ACTUAL_ROUTES_FILEPATH, newline='') as in_file:
        actual_routes = json.load(in_file)
except FileNotFoundError:
    print("The '{}' file is missing!".format(ACTUAL_ROUTES_FILEPATH))
except JSONDecodeError:
    print("Error in the '{}' JSON data!".format(ACTUAL_ROUTES_FILEPATH))
except Exception as e:
    print("Error when reading the '{}' file!".format(ACTUAL_ROUTES_FILEPATH))
    print(e)

if actual_routes:
    print('Printing Input Data')
    print('actual_routes:', actual_routes)

    # Solve for life the universe and everything
    print('Initializing Quark Reducer')
    time.sleep(1)
    print('Placing Nano Tubes In Gravitational Wavepool')
    time.sleep(1)
    print('Measuring Particle Deviations')
    time.sleep(1)
    print('Programming Artificial Noggins')
    time.sleep(1)
    print('Beaming in Complex Materials')
    time.sleep(1)
    print('Solving Model')
    time.sleep(1)
    print('Saving Solved Model State')
    time.sleep(1)
    output={
        'Message':'Hello from the setup.py script!',
        'Algorithm':"Initialize Gizmo",
        'Algorithm_Parameter': 32
    }

    # Write output data
    with open(MODEL_BUILD_OUTPUT_FILEPATH, 'w') as out_file:
        json.dump(output, out_file)
        print("Setup: The '{}' file has been saved".format(MODEL_BUILD_OUTPUT_FILEPATH))
