from json import dump, load, JSONDecodeError
from os import path
import score

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

    # Read JSON time inputs
    model_build_time = read_json_data(path.join(BASE_DIR,'data/model_score_timings/model_build_time.json'))
    model_apply_time = read_json_data(path.join(BASE_DIR,'data/model_score_timings/model_apply_time.json'))

    output=score.evaluate(
        actual_routes_json=path.join(BASE_DIR,'data/model_score_inputs/input.json'),
        submission_json=path.join(BASE_DIR,'data/model_apply_outputs/output.json'),
        cost_matrices_json=path.join(BASE_DIR,'data/model_apply_inputs/prediction_cost_matrices.json'),
        invalid_scores_json=path.join(BASE_DIR,'data/model_apply_outputs/output.json'),
        model_apply_time=model_apply_time.get("time"),
        model_build_time=model_build_time.get("time")
    )


    if model_build_time and model_apply_time and score_inputs:
        score = generate_score(model_build_time, model_apply_time, score_inputs)
        # Write output data
        with open(path.join(
            MODEL_SCORE_OUTPUTS_DIR,
            MODEL_SCORE_OUT_FILENAME
        ), 'w') as out_file:
            dump({ "score": score }, out_file)
            print('{0} Your score is: {1} of {2}'.format(
                get_feedback(score),
                score,
                MAX_SCORE
            ))
