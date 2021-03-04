import os, json
# Import local score file
import score

# Read JSON data from the given filepath
def read_json_data(filepath):
    try:
        with open(filepath, newline = '') as in_file:
            return json.load(in_file)
    except FileNotFoundError:
        print("The '{}' file is missing!".format(filepath))
    except json.JSONDecodeError:
        print("Error in the '{}' JSON data!".format(filepath))
    except Exception as e:
        print("Error when reading the '{}' file!".format(filepath))
        print(e)
    return None

if __name__ == '__main__':
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

    # Read JSON time inputs
    model_build_time = read_json_data(os.path.join(BASE_DIR,'data/model_score_timings/model_build_time.json'))
    model_apply_time = read_json_data(os.path.join(BASE_DIR,'data/model_score_timings/model_apply_time.json'))

    output=score.evaluate(
        actual_routes_json=os.path.join(BASE_DIR,'data/model_score_inputs/acttual_routes.json'),
        submission_json=os.path.join(BASE_DIR,'data/model_apply_outputs/predicted_routes.json'),
        cost_matrices_json=os.path.join(BASE_DIR,'data/model_apply_inputs/prediction_cost_matrices.json'),
        invalid_scores_json=os.path.join(BASE_DIR,'data/model_score_inputs/invalid_scores.json'),
        model_apply_time=model_apply_time.get("time"),
        model_build_time=model_build_time.get("time")
    )


    output_dir = os.path.join(BASE_DIR,'data/model_score_outputs/evaluation_output.json')
    with open(output_dir, 'w') as out_file:
        json.dump(output, out_file)
        print(output)
