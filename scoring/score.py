import numpy as np
import json
import sys

def read_json_data(filepath):
    '''
    Loads JSON file and generates a dictionary from it.

    Parameters
    ----------
    filepath : str
        Path of desired file.

    Raises
    ------
    JSONDecodeError
        The file exists and is readable, but it does not have the proper
        formatting for its place in the inputs of evaluate.

    Returns
    -------
    file : dict
        Dictionary form of the JSON file to which filepath points.

    '''
    try:
        with open(filepath, newline = '') as in_file:
            file=json.load(in_file)
            in_file.close()
    except FileNotFoundError:
        print("The '{}' file is missing!".format(filepath))
        sys.exit()
    except Exception as e:
        print("Error when reading the '{}' file!".format(filepath))
        print(e)
        sys.exit()
    return file

def good_format(file,input_type,filepath):
    '''
    Checks if input dictionary has proper formatting.
    
    Parameters
    ----------
    file : dict
        Dictionary loaded from evaluate input file.
    input_type : str
        Indicates which input of evaluate the current file is. Can be
        "actual," "prediction," "costs," or "invalids."
    filepath : str
        Path from which file was loaded.

    Raises
    ------
    JSONDecodeError
        The file exists and is readable, but it does not have the proper
        formatting for its place in the inputs of evaluate.

    Returns
    -------
    None.

    '''
    
    for route in file:
        if route[:8]!='RouteID_':
            raise JSONDecodeError('Improper route ID in {}. Every route must be denoted by a string that begins with "RouteID_".'.format(filepath))
    if input_type=='prediction' or input_type=='actual':
        for route in file:
            if type(file[route])!=dict or len(file[route])!=1: 
                raise JSONDecodeError('Improper route in {}. Each route ID must map to a dictionary with a single key.'.format(filepath))
            if input_type not in file[route]:
                if input_type=='prediction':
                    raise JSONDecodeError('Improper route in {}. Each route\'s dictionary in a projected sequence file must have the key, "prediction".'.format(filepath))
                else:
                    raise JSONDecodeError('Improper route in {}. Each route\'s dictionary in an actual sequence file must have the key, "actual".'.format(filepath))
            if type(file[route][input_type])!=dict:
                raise JSONDecodeError('Improper route in {}. Each sequence must be in the form of a dictionary.'.format(filepath))
            num_stops=len(file[route][input_type])
            for stop in file[route][input_type]:
                if type(stop)!=str or len(stop)!=2:
                    raise JSONDecodeError('Improper stop ID in {}. Each stop must be denoted by a two-letter ID string.'.format(filepath))
                stop_num=file[route][input_type][stop]
                if type(stop_num)!=int or stop_num>=num_stops:
                    raise JSONDecodeError('Improper stop number in {}. Each stop\'s position number, x, must be an integer in the range 0<=x<N where N is the number of stops in the route (including the depot).'.format(filepath))
    if input_type=='costs':
        for route in file:
            if type(file[route])!=dict:
                raise JSONDecodeError('Improper matrix in {}. Each cost matrix must be a dictionary.'.format(filepath)) 
            for origin in file[route]:
                if type(origin)!=str or len(origin)!=2:
                    raise JSONDecodeError('Improper stop ID in {}. Each stop must be denoted by a two-letter ID string.'.format(filepath))
                if type(file[route][origin])!=dict:
                    raise JSONDecodeError('Improper matrix in {}. Each origin in a cost matrix must map to a dictionary of destinations'.format(filepath))
                for dest in file[route][origin]:
                    if type(dest)!=str or len(dest)!=2:
                        raise JSONDecodeError('Improper stop ID in {}. Each stop must be denoted by a two-letter ID string.'.format(filepath))
                    if not(type(file[route][origin][dest])==float or type(file[route][origin][dest])==int):
                        raise JSONDecodeError('Improper time in {}. Every travel time must be a float or int.'.format(filepath))
    if input_type=='invalids':
        for route in file:
            if not(type(file[route])==float or type(file[route])==int):
                raise JSONDecodeError('Improper score in {}. Every score in an invalid score file must be a float or int.'.format(filepath))

class JSONDecodeError(Exception):
    pass

def evaluate(actual_routes_json,submission_json,cost_matrices_json, invalid_scores_json,**kwargs):
    '''
    Calculates score for a submission.

    Parameters
    ----------
    actual_routes_json : str
        filepath of JSON of actual routes.
    submission_json : str
        filepath of JSON of participant-created routes.
    cost_matrices_json : str
        filepath of JSON of estimated times to travel between stops of routes.
    invalid_scores_json : str
        filepath of JSON of scores assigned to routes if they are invalid.
    **kwargs :
        Inputs placed in output. Intended for testing_time_seconds and
        training_time_seconds

    Returns
    -------
    scores : dict
        Dictionary containing submission score, individual route scores, feasibility
        of routes, and kwargs.

    '''
    actual_routes=read_json_data(actual_routes_json)
    good_format(actual_routes,'actual',actual_routes_json)
    submission=read_json_data(submission_json)
    good_format(submission,'prediction',submission_json)
    cost_matrices=read_json_data(cost_matrices_json)
    good_format(cost_matrices,'costs',cost_matrices_json)
    invalid_scores=read_json_data(invalid_scores_json)
    good_format(invalid_scores,'invalids',invalid_scores_json)
    scores={'submission_score':'x','route_scores':{},'route_feasibility':{}}
    for kwarg in kwargs:
        scores[kwarg]=kwargs[kwarg]
    for route in actual_routes:
        if route not in submission:
            scores['route_scores'][route]=invalid_scores[route]
            scores['route_feasibility'][route]=False
        else:
            actual_dict=actual_routes[route]
            actual=route2list(actual_dict)
            try:
                sub_dict=submission[route]
                sub=route2list(sub_dict)
            except:
                scores['route_scores'][route]=invalid_scores[route]
                scores['route_feasibility'][route]=False
            else:
                if isinvalid(actual,sub):
                    scores['route_scores'][route]=invalid_scores[route]
                    scores['route_feasibility'][route]=False
                else:
                     cost_mat=cost_matrices[route]
                     scores['route_scores'][route]=score(actual,sub,cost_mat)
                     scores['route_feasibility'][route]=True
    submission_score=np.mean(list(scores['route_scores'].values()))
    scores['submission_score']=submission_score
    return scores

def score(actual,sub,cost_mat,g=1000):
    '''
    Scores individual routes.

    Parameters
    ----------
    actual : list
        Actual route.
    sub : list
        Submitted route.
    cost_mat : dict
        Cost matrix.
    g : int/float, optional
        ERP gap penalty. Irrelevant if large and len(actual)==len(sub). The
        default is 1000.

    Returns
    -------
    float
        Accuracy score from comparing sub to actual.

    '''
    norm_mat=normalize_matrix(cost_mat)
    return seq_dev(actual,sub)*erp_count(actual,sub,norm_mat,g)

def erp_count(actual,sub,matrix,g=1000):
    '''
    Outputs ERP of comparing sub to actual divided by the number of edits involved
    in the ERP. If there are 0 edits, returns 0 instead.

    Parameters
    ----------
    actual : list
        Actual route.
    sub : list
        Submitted route.
    matrix : dict
        Normalized cost matrix.
    g : int/float, optional
        ERP gap penalty. The default is 1000.

    Returns
    -------
    int/float
        ERP divided by number of ERP edits or 0 if there are 0 edits.

    '''
    total,count=erp_count_helper(actual,sub,matrix,g)
    if count==0:
        return 0
    else:
        return total/count

def erp_count_helper(actual,sub,matrix,g=1000,memo=None):
    '''
    Calculates ERP and counts number of edits in the process.

    Parameters
    ----------
    actual : list
        Actual route.
    sub : list
        Submitted route.
    matrix : dict
        Normalized cost matrix.
    g : int/float, optional
        Gap penalty. The default is 1000.
    memo : dict, optional
        For memoization. The default is None.

    Returns
    -------
    d : float
        ERP from comparing sub to actual.
    count : int
        Number of edits in ERP.

    '''
    if memo==None:
        memo={}
    actual_tuple=tuple(actual)
    sub_tuple=tuple(sub)
    if (actual_tuple,sub_tuple) in memo:
        d,count=memo[(actual_tuple,sub_tuple)]
        return d,count
    if len(sub)==0:
        d=gap_sum(actual,g)
        count=len(actual)
    elif len(actual)==0:
        d=gap_sum(sub,g)
        count=len(sub)
    else:
        head_actual=actual[0]
        head_sub=sub[0]
        rest_actual=actual[1:]
        rest_sub=sub[1:]
        score1,count1=erp_count_helper(rest_actual,rest_sub,matrix,g,memo)
        score2,count2=erp_count_helper(rest_actual,sub,matrix,g,memo)
        score3,count3=erp_count_helper(actual,rest_sub,matrix,g,memo)
        option_1=score1+dist_erp(head_actual,head_sub,matrix,g)
        option_2=score2+dist_erp(head_actual,'gap',matrix,g)
        option_3=score3+dist_erp(head_sub,'gap',matrix,g)
        d=min(option_1,option_2,option_3)
        if d==option_1:
            if head_actual==head_sub:
                count=count1
            else:
                count=count1+1
        elif d==option_2:
            count=count2+1
        else:
            count=count3+1
    memo[(actual_tuple,sub_tuple)]=(d,count)
    return d,count

def normalize_matrix(mat):
    '''
    Normalizes cost matrix.

    Parameters
    ----------
    mat : dict
        Cost matrix.

    Returns
    -------
    new_mat : dict
        Normalized cost matrix.

    '''
    new_mat=mat.copy()
    time_list=[]
    for origin in mat:
        for destination in mat[origin]:
            time_list.append(mat[origin][destination])
    avg_time=np.mean(time_list)
    std_time=np.std(time_list)
    min_new_time=np.inf
    for origin in mat:
        for destination in mat[origin]:
            old_time=mat[origin][destination]
            new_time=(old_time-avg_time)/std_time
            if new_time<min_new_time:
                min_new_time=new_time
            new_mat[origin][destination]=new_time
    for origin in new_mat:
        for destination in new_mat[origin]:
            new_time=new_mat[origin][destination]
            shifted_time=new_time-min_new_time
            new_mat[origin][destination]=shifted_time
    return new_mat

def gap_sum(path,g):
    '''
    Calculates ERP between two sequences when at least one is empty.

    Parameters
    ----------
    path : list
        Sequence that is being compared to an empty sequence.
    g : int/float
        Gap penalty.

    Returns
    -------
    res : int/float
        ERP between path and an empty sequence.

    '''
    res=0
    for p in path:
        res+=g
    return res

def dist_erp(p_1,p_2,mat,g=1000):
    '''
    Finds cost between two points. Outputs g if either point is a gap.

    Parameters
    ----------
    p_1 : str
        ID of point.
    p_2 : str
        ID of other point.
    mat : dict
        Normalized cost matrix.
    g : int/float, optional
        Gap penalty. The default is 1000.

    Returns
    -------
    dist : int/float
        Cost of substituting one point for the other.

    '''
    if p_1=='gap' or p_2=='gap':
        dist=g
    else:
        dist=mat[p_1][p_2]
    return dist

def seq_dev(actual,sub):
    '''
    Calculates sequence deviation.

    Parameters
    ----------
    actual : list
        Actual route.
    sub : list
        Submitted route.

    Returns
    -------
    float
        Sequence deviation.

    '''
    actual=actual[1:-1]
    sub=sub[1:-1]
    comp_list=[]
    for i in sub:
        comp_list.append(actual.index(i))
        comp_sum=0
    for ind in range(1,len(comp_list)):
        comp_sum+=abs(comp_list[ind]-comp_list[ind-1])-1
    n=len(actual)
    return (2/(n*(n-1)))*comp_sum

def isinvalid(actual,sub):
    '''
    Checks if submitted route is invalid.

    Parameters
    ----------
    actual : list
        Actual route.
    sub : list
        Submitted route.

    Returns
    -------
    bool
        True if route is invalid. False otherwise.

    '''
    if len(actual)!=len(sub) or set(actual)!=set(sub):
        return True
    elif actual[0]!=sub[0]:
        return True
    else:
        return False

def route2list(route_dict):
    '''
    Translates route from dictionary to list.

    Parameters
    ----------
    route_dict : dict
        Route as a dictionary.

    Returns
    -------
    route_list : list
        Route as a list.

    '''
    if 'prediction' in route_dict:
        stops=route_dict['prediction']
    elif 'actual' in route_dict:
        stops=route_dict['actual']
    route_list=[0]*(len(stops)+1)
    for stop in stops:
        route_list[stops[stop]]=stop
    route_list[-1]=route_list[0]
    return route_list
