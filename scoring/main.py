import os, json, time
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

    print('Beginning Score Evaluation... ', end='')
    output = score.evaluate(
        actual_routes_json = os.path.join(BASE_DIR,'data/model_score_inputs/new_actual_sequences.json'),
        invalid_scores_json = os.path.join(BASE_DIR,'data/model_score_inputs/new_invalid_sequence_scores.json'),
        submission_json = os.path.join(BASE_DIR,'data/model_apply_outputs/proposed_sequences.json'),
        cost_matrices_json = os.path.join(BASE_DIR,'data/model_apply_inputs/new_travel_times.json'),
        model_apply_time = model_apply_time.get("time"),
        model_build_time = model_build_time.get("time")
    )
    print('done')

    # Write Outputs to File
    output_dir = os.path.join(BASE_DIR,'data/model_score_outputs/evaluation_output.json')
    with open(output_dir, 'w') as out_file:
        json.dump(output, out_file)

    # Print Pretty Output
    output=json.loads(output)
    print("\nsubmission_score:", output.get('submission_score'))
    rt_show=output.get('route_scores')
    extra_str=None
    if len(rt_show.keys())>5:
        rt_show=dict(zip(rt_show.items()[0:5]))
        extra_str="\n..."
        print("\nFirst five route_scores:")
    else:
        print("\nroute_scores:")
    for rt_key, rt_score in rt_show.items():
        print(rt_key,": ",rt_score)
        if extra_str:
            print(extra_str)
