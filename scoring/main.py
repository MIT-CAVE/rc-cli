from json import dump, load
from os import path

from random import randrange

MIN_SCORE = 0
MAX_SCORE = 100

def get_feedback(score):
    score_range = MAX_SCORE - MIN_SCORE
    score_norm = (score - MIN_SCORE) / score_range
    if score_norm >= 0 && score_norm <= 0.4:
        return 'Keep up the good work!'
    elif score_norm > 0.4 * score_norm <= 0.6:
        return 'Nice job!'
    elif score_norm > 0.6 && score_norm <= 0.8:
        return 'Great job!'
    elif score_norm > 0.8 && score_norm <= 1:
        return 'Excellent!'
    else
        return 'Error in scoring algorithm:'

# MLL's magic
def generate_score(data):
    return randrange(MIN_SCORE, MAX_SCORE) # FIXME

if __name__ == '__main__':
    BASE_DIR = path.dirname(path.abspath(__file__))
    DATA_DIR = path.join(BASE_DIR, 'data')
    INPUTS_DIR = path.join(DATA_DIR, 'scoring_inputs')
    OUTPUTS_DIR = path.join(DATA_DIR, 'scoring_outputs')

    # Read input data
    with open(path.join(INPUTS_DIR, 'evaluate-out.json'), newline='') as in_file:
        data = load(in_file)

    score = generate_score(data)
    # Write output data
    with open(path.join(OUTPUTS_DIR, 'scoring-out.json'), 'w') as out_file:
        dump({ "score": score }, out_file)
        print('{0} Your score is: {1} of {2}\n'.format(
            get_feedback(score),
            score,
            MAX_SCORE
        ))
