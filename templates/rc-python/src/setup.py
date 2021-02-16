from os import path
import sys, json, csv, time

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
SETUP_INPUTS_DIR = path.join(DATA_DIR, 'setup_inputs')
SETUP_OUTPUTS_DIR = path.join(DATA_DIR, 'setup_outputs')

# Read input data
print('Reading Input Data')
with open(path.join(SETUP_INPUTS_DIR, 'setup-in.csv'), newline='') as setup_in:
    setup_in = [i for i in csv.reader(setup_in, delimiter=',', quotechar='|')]

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
with open(path.join(SETUP_OUTPUTS_DIR, 'setup-out.json'), 'w') as out_file:
    json.dump(output, out_file)
    print((
        "Setup: A file, 'setup-out.json', has been saved in {}".format(SETUP_OUTPUTS_DIR)
    ))
