from json import dump, load, JSONDecodeError
from os import path

from random import randrange

# Constants
MIN_SCORE = 0
MAX_SCORE = 100
TIME_STATS_FILENAME = 'time_stats.json'
SCORING_INPUT_FILENAME = 'foo.json'

def get_feedback(score):
    score_range = MAX_SCORE - MIN_SCORE
    score_norm = (score - MIN_SCORE) / score_range
    if score_norm >= 0 and score_norm <= 0.4:
        return 'Keep up the good work!'
    elif score_norm > 0.4 and score_norm <= 0.6:
        return 'Nice job!'
    elif score_norm > 0.6 and score_norm <= 0.8:
        return 'Great job!'
    elif score_norm > 0.8 and score_norm <= 1:
        return 'Excellent!'
    else:
        return 'Error in scoring algorithm:'

# MLL's magic
def generate_score(time_stats, extra):
    return randrange(MIN_SCORE, MAX_SCORE) # FIXME

# Read JSON data from the given filepath
def read_json_data(filepath):
    try:
        with open(filepath, newline = '') as in_file:
            return load(in_file)
    except FileNotFoundError:
        print("The '{}' file is missing!".format(filepath))
    except JSONDecodeError:
        print("Error in the '{}' JSON data!".format(filepath))
    except Exception as e:
        print("Error when reading the '{}' file!".format(filepath))
        print(e)
    return None

if __name__ == '__main__':
    BASE_DIR = path.dirname(path.abspath(__file__))
    DATA_DIR = path.join(BASE_DIR, 'data')
    EVALUATE_OUTPUTS_DIR = path.join(DATA_DIR, 'evaluate_outputs')
    SCORING_INPUTS_DIR = path.join(DATA_DIR, 'scoring_inputs')
    SCORING_OUTPUTS_DIR = path.join(DATA_DIR, 'scoring_outputs')

    # Read JSON input data
    time_stats = read_json_data(path.join(
        EVALUATE_OUTPUTS_DIR,
        TIME_STATS_FILENAME
    ))
    score_inputs = read_json_data(path.join(
        SCORING_INPUTS_DIR,
        SCORING_INPUT_FILENAME
    ))
    if time_stats and score_inputs:
        score = generate_score(time_stats, score_inputs)
        # Write output data
        with open(path.join(
            SCORING_OUTPUTS_DIR,
            'scoring-out.json'
        ), 'w') as out_file:
            dump({ "score": score }, out_file)
            print('{0} Your score is: {1} of {2}'.format(
                get_feedback(score),
                score,
                MAX_SCORE
            ))
