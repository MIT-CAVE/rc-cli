from csv import reader
from json import dump
from os import path
import sys

if __name__ == '__main__':
    run_mode = sys.argv[1]
    BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
    DATA_DIR = path.join(BASE_DIR, 'data')
    INPUTS_DIR = path.join(DATA_DIR, '{}_inputs'.format(run_mode))
    OUTPUTS_DIR = path.join(DATA_DIR, '{}_outputs'.format(run_mode))

    # Read input data
    with open(path.join(INPUTS_DIR, '{}-in.csv'.format(run_mode)), newline='') as in_file:
        data_reader = reader(in_file, delimiter=',', quotechar='|')
        for row in data_reader:
            print(' '.join(row))

    # Write output data
    with open(path.join(OUTPUTS_DIR, '{}-out.json'.format(run_mode)), 'w') as out_file:
        dump({ run_mode: 'Hello World from the app!' }, out_file)
        print((
            "2. A file '{0}-out.json' has been written in the directory"
            " './apps/{1}/data/{0}_outputs'".format(
                run_mode,
                path.basename(BASE_DIR)
            )
        ))
