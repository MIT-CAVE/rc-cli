from csv import reader
from os import path
from json import dump

if __name__ == '__main__':
    BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
    DATA_DIR = path.join(BASE_DIR, 'data')

    # Read input data
    with open(path.join(DATA_DIR, 'test.csv'), newline='') as in_file:
        data_reader = reader(in_file, delimiter=',', quotechar='|')
        for row in data_reader:
            print(' '.join(row))

    # Write output data
    with open(path.join(DATA_DIR, 'output.json'), 'w') as out_file:
        dump({ 'output': 'Hello World from the app!' }, out_file)
        print(
            "2. A file 'output.json' has been written in the directory 'data'"
        )
