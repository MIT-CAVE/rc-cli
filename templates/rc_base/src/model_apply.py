from os import path
import sys, json, time

BASE_DIR = path.dirname(path.dirname(path.abspath(__file__)))
model_path=path.join(BASE_DIR, 'data/model_build_outputs/model.json')
with open(model_path, newline='') as in_file:
    model_build_out = json.load(in_file)

prediction_routes_path=path.join(BASE_DIR, 'data/model_apply_inputs/prediction_routes.json')
with open(prediction_routes_path, newline='') as in_file:
    prediction_routes = json.load(in_file)

def sort_by_key(stops, sort_by):
    stops_list=[{**value, **{'id':key}} for key, value in stops.items()]
    ordered_stop_list=sorted(stops_list, key=lambda x: x[sort_by])
    ordered_stop_list_ids=[i['id'] for i in ordered_stop_list]
    return {i:ordered_stop_list_ids.index(i) for i in ordered_stop_list_ids}

def predict_all_routes(prediction_routes, sort_by):
    return {key:{'prediction':sort_by_key(stops=value['stops'], sort_by=sort_by)} for key, value in prediction_routes.items()}

sort_by=model_build_out.get("sort_by")
output=predict_all_routes(prediction_routes=prediction_routes, sort_by=sort_by)

output_path=path.join(BASE_DIR, 'data/model_apply_outputs/predicted_routes.json')
with open(output_path, 'w') as out_file:
    json.dump(output, out_file)
