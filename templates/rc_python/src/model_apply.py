from os import path
import sys, json, csv, time

# Get Data Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
DATA_DIR = path.join(BASE_DIR, 'data')

# Get various input and output directories
SETUP_OUTPUTS_DIR = path.join(DATA_DIR, 'setup_outputs')
EVALUATE_INPUTS_DIR = path.join(DATA_DIR, 'evaluate_inputs')
EVALUATE_OUTPUTS_DIR = path.join(DATA_DIR, 'evaluate_outputs')

# I/O Files
SETUP_OUTPUT_FILEPATH = path.join(SETUP_OUTPUTS_DIR, 'setup_out.json')
EVALUATE_INPUT_FILEPATH = path.join(EVALUATE_INPUTS_DIR, 'evaluate_in.csv')
EVALUATE_OUTPUT_FILEPATH = path.join(EVALUATE_OUTPUTS_DIR, 'predicted_routes.json')

# Read input data
print('Reading Input Data')
# Setup output
setup_out = None
try:
    with open(SETUP_OUTPUT_FILEPATH, newline='') as in_file:
        setup_out = json.load(in_file)
except FileNotFoundError:
    print("The '{}' file is missing!".format(SETUP_OUTPUT_FILEPATH))
except JSONDecodeError:
    print("Error in the '{}' JSON data!".format(SETUP_OUTPUT_FILEPATH))
except Exception as e:
    print("Error when reading the '{}' file!".format(SETUP_OUTPUT_FILEPATH))
    print(e)
# Evaluate input
evaluate_in = None
try:
    with open(EVALUATE_INPUT_FILEPATH, newline='') as in_file:
        evaluate_in = [
            i for i in csv.reader(in_file, delimiter=',', quotechar='|')
        ]
except FileNotFoundError:
    print("The '{}' file is missing!".format(EVALUATE_INPUT_FILEPATH))
except csv.Error:
    print("Error in the '{}' CSV data!".format(EVALUATE_INPUT_FILEPATH))
except Exception as e:
    print("Error when reading the '{}' file!".format(EVALUATE_INPUT_FILEPATH))
    print(e)

if setup_out and evaluate_in:
    print('Printing Input Data')
    print('model from setup_out:', setup_out)
    print('data for evaluate_in:', evaluate_in)
    time.sleep(1)
    # Solve for life the universe and everything
    print('{} Algorithm'.format(setup_out.get("Algorithm","No Provided")))
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
    with open(EVALUATE_OUTPUT_FILEPATH, 'w') as out_file:
        json.dump(output, out_file)
        print("Evaluate: The '{}' file has been saved".format(
            EVALUATE_OUTPUT_FILEPATH
        ))
