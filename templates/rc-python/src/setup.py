from csv import reader
from json
from os import path
import sys

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
SETUP_INPUTS_DIR = path.join(DATA_DIR, 'setup_inputs')
SETUP_OUTPUTS_DIR = path.join(DATA_DIR, 'setup_outputs')

# Read input data
print('Reading Input Data')
with open(path.join(EVALUATE_INPUTS_DIR, 'setup-in.csv'), newline='') as setup_in:
    setup_in = [i for i in reader(evaluate_in, delimiter=',', quotechar='|')]

print('Printing Input Data')
print('setup_in:', setup_in)

# Solve for life the universe and everything
print('Initializing Quark Reducer')
print('Placing Nano Tubes In Gravitational Wavepool')
print('Measuring Particle Deviations')
print('Programming Artificial Brain')
print('Beaming in Materials')
print('Solving Model')
print('Saving Solved Model State')
output={
    'Message':'Hello from the setup.py script!',
    'Algorithm':"Initialize Gizmo",
    'Algorithm_Parameter': 32
}

# Write output data
with open(path.join(SETUP_OUTPUTS_DIR, 'setup-out.json'), 'w') as out_file:
    json.dump(output, out_file)
    print((
        "Setup: A file, 'setup-out.json', has been saved in {}".format(SETUP_OUTPUTS_DIR)
    ))
