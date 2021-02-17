from os import path
import sys, json, csv, time

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
SETUP_INPUTS_DIR = path.join(DATA_DIR, 'setup_inputs')
SETUP_OUTPUTS_DIR = path.join(DATA_DIR, 'setup_outputs')

# I/O Files
SETUP_INPUT_FILEPATH = path.join(SETUP_INPUTS_DIR, 'setup-in.csv')
SETUP_OUTPUT_FILEPATH = path.join(SETUP_OUTPUTS_DIR, 'setup-out.json')

# Read input data
print('Reading Input Data')
setup_in = None
try:
    with open(SETUP_INPUT_FILEPATH, newline='') as in_file:
        setup_in = [
            i for i in csv.reader(in_file, delimiter=',', quotechar='|')
        ]
except FileNotFoundError:
    print("The '{}' file is missing!".format(SETUP_INPUT_FILEPATH))
except csv.Error:
    print("Error in the '{}' CSV data!".format(SETUP_INPUT_FILEPATH))
except Exception as e:
    print("Error when reading the '{}' file!".format(SETUP_INPUT_FILEPATH))
    print(e)

if setup_in:
    print('Printing Input Data')
    print('setup_in:', setup_in)

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
    with open(SETUP_OUTPUT_FILEPATH, 'w') as out_file:
        json.dump(output, out_file)
        print("Setup: The '{}' file has been saved".format(SETUP_OUTPUT_FILEPATH))
