from csv import reader
from json
from os import path
import sys

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
SETUP_OUTPUTS_DIR = path.join(DATA_DIR, 'setup_outputs')
EVALUATE_INPUTS_DIR = path.join(DATA_DIR, 'evaluate_inputs')
EVALUATE_OUTPUTS_DIR = path.join(DATA_DIR, 'evaluate_outputs')

# Read input data
print('Reading Input Data')
with open(path.join(EVALUATE_INPUTS_DIR, 'evaluate-in.csv'), newline='') as evaluate_in:
    evaluate_in = [i for i in reader(evaluate_in, delimiter=',', quotechar='|')]

with open(path.join(SETUP_OUTPUTS_DIR, 'setup-out.json')) as setup_out:
    try:
        setup_out = json.load(setup_out)
    except:
        print('setup_out.json is missing!')
        setup_out=None

print('Printing Input Data')
print('model from setup_out:', setup_out)
print('data for evaluate_in:', evaluate_in)

# Solve for life the universe and everything
print('{} Algorithm'.format(setup.get("Algorithm","No Provided")))
print('Solving Dark Matter Waveforms')
print('Quantum Computer is Overheating')
print('Trying Alternate Measurement Cycles')
print('Found a Great Solution!')
print('Checking Validity')
print('The Answer is 42!')
output={
    'Message':'Hello from the evaluation script!',
    'The_Answer_To_Life':42
}

# Write output data
with open(path.join(EVALUATE_OUTPUTS_DIR, 'predicted_routes.json'), 'w') as out_file:
    json.dump(output, out_file)
    print((
        "Evaluate: A file, 'predicted_routes.json', has been saved in {}".format(EVALUATE_OUTPUTS_DIR)
    ))
