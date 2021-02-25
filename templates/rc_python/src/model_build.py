from os import path
import sys, json, time

# Get Directory
BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))

# Read input data
print('Reading Input Data')
training_routes_path=path.join(BASE_DIR, 'data/model_build_inputs/training_routes.json')
with open(training_routes_path, newline='') as in_file:
    actual_routes = json.load(in_file)


# Solve for something hard
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
output={
    'Model':'Hello from the model_build.py script!',
    'sort_by':'lat'
}

# Write output data
model_path=path.join(BASE_DIR, 'data/model_build_outputs/model.json')
with open(model_path, 'w') as out_file:
    json.dump(output, out_file)
    print("Success: The '{}' file has been saved".format(model_path))
