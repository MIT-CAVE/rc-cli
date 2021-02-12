from json import dump, load
from os import path

from random import randrange

MIN_SCORE = 0
MAX_SCORE = 100

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
def generate_score(benchmark, extra):
    return randrange(MIN_SCORE, MAX_SCORE) # FIXME

if __name__ == '__main__':
    BASE_DIR = path.dirname(path.abspath(__file__))
    DATA_DIR = path.join(BASE_DIR, 'data')
    EVALUATE_OUTPUTS_DIR = path.join(DATA_DIR, 'evaluate_outputs')
    SCORING_INPUTS_DIR = path.join(DATA_DIR, 'scoring_inputs')
    SCORING_OUTPUTS_DIR = path.join(DATA_DIR, 'scoring_outputs')

    # Read evaluate_outputs data
    with open(path.join(EVALUATE_OUTPUTS_DIR, 'benchmark.json'), newline='') as in_file:
        benchmark_data = load(in_file)
    # Read scoring_inputs data
    with open(path.join(SCORING_INPUTS_DIR, 'foo.json'), newline='') as in_file:
        foo_input = load(in_file)

    score = generate_score(benchmark_data, foo_input)
    # Write output data
    with open(path.join(SCORING_OUTPUTS_DIR, 'scoring-out.json'), 'w') as out_file:
        dump({ "score": score }, out_file)
        print('{0} Your score is: {1} of {2}'.format(
            get_feedback(score),
            score,
            MAX_SCORE
        ))
