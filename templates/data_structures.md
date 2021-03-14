# Data structures
## Introduction
Data is at the very heart of your project. In order for you to correctly parse the input files in your program and generate the correct format for the output files in each phase (`model-build` and `model-apply`), you must become familiar with the input and output data structures.

In this document we provide each data format of the input and output files included in the `data` folder.

## `data/`
In each "Data Format" section, some placeholder elements are specified to provide information about the property regarding its context or value type. All placeholders are enclosed in double quotes and angle brackets `"<>"`. However, if you are not sure about the value of a property, expand the "Example" below the data structure.
- `<YYYY-MM-DD>`: an ISO 8601 compliant date format
- `<YYYY-MM-DD hh:mm:ss>`: an ISO 8601 compliant datetime format that typically represents a timestamp
- `<bool-value>`: a boolean value (`false`, `true`)
- `<float-number>`: a decimal number
- `<hex-hash>`: a hexadecimal hash appended to the `RouteID` or `PackageID` property
- `<hh:mm:ss>`: a time format in hours, minutes, and seconds
- `<proc-status>`: status of a `model-build` or `model-apply` run (`success` | `failure` | `timeout`)
- `<route-score>`: a qualifier for the route (`Average` | `Good`)
- `<scan-status>`: status of a package (`DELIVERED` | `DELIVERY_ATTEMPTED`)
- `<station-code>`: a string identifier for a station
- `<stop-id>`: a random two-letter code for a stop ID (`AA`| `AB`|...|`ZZ`)
- `<stop-type>`: a stop type (`Dropoff` | `Station`)
- `<uint-number>`: an integer number contained in the `[0, 65535]` range
- `<uint32-number>`: an integer number contained in the `[0, 4294967295]` range
- `<zone-id>`: a string identifier for a zone within the stop

### `model_build_inputs`:
1. `actual_sequences.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "actual": {
          "<stop-id>": "<uint-number>",
          "..."
        }
      },
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a279ac2-41aa-4a5e-85de-061f3475896c": {
          "actual": {
            "AA": 182,
            "AC": 168,
            "AD": 35,
            "AJ": 22
          }
        },
        "RouteID_1a2bfa66-0a93-4e55-a261-0e341b6f05b6": {
          "actual": {
            "AA": 137,
            "AM": 173
          }
        },
        "RouteID_1a48f1f3-d2a2-4431-a078-18f832745700": {
          "actual": {
            "AA": 65,
            "AD": 127,
            "AG": 48
          }
        }
      }
      ```
    </details>


2. `invalid_sequence_scores.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": "<float-number>",
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a279ac2-41aa-4a5e-85de-061f3475896c": 1.396440219978261,
        "RouteID_1a2bfa66-0a93-4e55-a261-0e341b6f05b6": 1.2147466479550677,
        "RouteID_1a48f1f3-d2a2-4431-a078-18f832745700": 1.2812543267775713,
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": 0.9012432765379605,
        "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": 0.7468055008554786
      }
      ```
    </details>


3. `package_data.json`

    Data format:
    ```json
    {
      "<RouteID_<hex-hash>": {
        "<stop-id>": {
          "PackageID_<hex-hash>": {
            "scan_status": "<scan-status>",
            "time_window": {
              "start_time_utc": "<YYYY-MM-DD hh:mm:ss>",
              "end_time_utc": "<YYYY-MM-DD hh:mm:ss>"
            },
            "planned_service_time_seconds": "<uint-number>",
            "dimensions": {
              "depth_cm": "<float-number>",
              "height_cm": "<float-number>",
              "width_cm": "<float-number>"
            }
          },
          "..."
        },
        "..."
      },
      "..."
    }
    ```

  <details>
  <summary>Example</summary>

  ```json
  {
    "RouteID_1a279ac2-41aa-4a5e-85de-061f3475896c": {
      "AA": {
        "PackageID_ad0f6eb7-8498-4c71-b1f1-dcd81e4bde9f": {
          "scan_status": "DELIVERED",
          "time_window": {
            "start_time_utc": "2018-07-23 14:00:00",
            "end_time_utc": "2018-07-23 21:00:00"
          },
          "planned_service_time_seconds": 84,
          "dimensions": {
            "depth_cm": 48.3,
            "height_cm": 15.2,
            "width_cm": 33
          }
        }
      },
      "AY": {
        "PackageID_0ed922ae-d59e-49c1-b71b-827e4353ffed": {
          "scan_status": "DELIVERED",
          "time_window": {
            "start_time_utc": "2018-07-23 15:00:00",
            "end_time_utc": "2018-07-23 22:00:00"
          },
          "planned_service_time_seconds": 18,
          "dimensions": {
            "depth_cm": 30.7,
            "height_cm": 2.3,
            "width_cm": 28.2
          }
        },
        "PackageID_254e2768-2f30-4731-a3e4-2e0f43268b25": {
          "scan_status": "DELIVERED",
          "time_window": {
            "start_time_utc": "2018-07-23 11:00:00",
            "end_time_utc": "2018-07-23 12:00:00"
          },
          "planned_service_time_seconds": 18,
          "dimensions": {
            "depth_cm": 35.8,
            "height_cm": 11.9,
            "width_cm": 32.5
          }
        }
      }
    }
  }
  ```
</details>


4. `route_data.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "station_code": "<station-code>",
        "date_YYYY_MM_DD": "<YYYY-MM-DD>",
        "departure_time_utc": "<hh:mm:ss>",
        "executor_capacity_cm3": "<uint32-number>",
        "route_score": "<route-score>",
        "stops": {
          "<stop-id>": {
            "lat": "<float-number>",
            "lng": "<float-number>",
            "type": "<stop-type>",
            "zone_id": "<zone-id>"
          },
          "..."
        },
        "..."
      },
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a279ac2-41aa-4a5e-85de-061f3475896c": {
          "station_code": "DAU1",
          "date_YYYY_MM_DD": "2018-07-23",
          "departure_time_utc": "15:36:07",
          "executor_capacity_cm3": 4247527,
          "route_score": "Average",
          "stops": {
            "AA": {
              "lat": 30.396307,
              "lng": -97.691442,
              "type": "Dropoff",
              "zone_id": "E-20.2H"
            },
            "AC": {
              "lat": 30.399494,
              "lng": -97.692166,
              "type": "Dropoff",
              "zone_id": "E-19.3H"
            },
            "AD": {
              "lat": 30.393832,
              "lng": -97.69988,
              "type": "Dropoff",
              "zone_id": "E-19.3J"
            }
          }
        },
        "RouteID_1a2bfa66-0a93-4e55-a261-0e341b6f05b6": {
          "station_code": "DLA5",
          "date_YYYY_MM_DD": "2018-08-07",
          "departure_time_utc": "16:00:58",
          "executor_capacity_cm3": 3313071,
          "route_score": "Good",
          "stops": {
            "AA": {
              "lat": 33.958825,
              "lng": -117.41668,
              "type": "Dropoff",
              "zone_id": "C-18.1C"
            },
            "AD": {
              "lat": 33.96314,
              "lng": -117.401855,
              "type": "Dropoff",
              "zone_id": "C-18.2A"
            }
          }
        }
      }
      ```
    </details>


5. `travel_times.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "<stop-id*>": {
          "<stop-id*>": 0,
          "<stop-id>": "<float-number>",
          "<stop-id>": "<float-number>",
          "..."
        },
        "<stop-id*>": {
          "<stop-id>": "<float-number>",
          "<stop-id*>": 0,
          "<stop-id>": "<float-number>",
          "..."
        },
        "..."
      },
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a279ac2-41aa-4a5e-85de-061f3475896c": {
          "AA": {
            "AA": 0,
            "AC": 211.5,
            "AD": 258.7,
            "AJ": 244.9
          },
          "AC": {
            "AA": 219.3,
            "AC": 0,
            "AD": 233,
            "AJ": 235.7
          }
        },
        "RouteID_1a2bfa66-0a93-4e55-a261-0e341b6f05b6": {
          "AA": {
            "AA": 0,
            "AD": 370.4
          },
          "AD": {
            "AA": 452.9,
            "AD": 0,
          }
        }
      }
      ```
    </details>


### `model_build_outputs`:
As for the model build output data, the file(s) generated in the `model-build` process can be in the format(s) that best suits your needs. Please note that the output file(s) should be used in your `model-apply` implementation.

### `model_apply_inputs`:
1. `new_package_data.json`

    Data format:
    ```json
    {
      "<RouteID_<hex-hash>": {
        "<stop-id>": {
          "PackageID_<hex-hash>": {
            "time_window": {
              "start_time_utc": "<YYYY-MM-DD hh:mm:ss>",
              "end_time_utc": "<YYYY-MM-DD hh:mm:ss>"
            },
            "planned_service_time_seconds": "<uint-number>",
            "dimensions": {
              "depth_cm": "<float-number>",
              "height_cm": "<float-number>",
              "width_cm": "<float-number>"
            }
          }
        },
        "..."
      },
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": {
          "AD": {
            "PackageID_e28a5205-bc08-4757-af6f-635946cd0551": {
              "time_window": {
                "start_time_utc": "2018-08-12 12:00:00",
                "end_time_utc": "2018-08-12 15:00:00"
              },
              "planned_service_time_seconds": 42,
              "dimensions": {
                "depth_cm": 31.8,
                "height_cm": 3.8,
                "width_cm": 19.1
              }
            }
          },
          "AR": {
            "PackageID_ef435cac-7555-4989-84da-330adae351b5": {
              "time_window": {
                "start_time_utc": "2018-08-13 1:00:00",
                "end_time_utc": "2018-08-13 2:30:00"
              },
              "planned_service_time_seconds": 36,
              "dimensions": {
                "depth_cm": 34.3,
                "height_cm": 11.4,
                "width_cm": 26.7
              }
            }
          },
          "AX": {
            "PackageID_4b50af8d-0fb8-49ed-ac5a-31ed1e19bce6": {
              "time_window": {
                "start_time_utc": "2018-08-14 14:00:00",
                "end_time_utc": "2018-08-14 21:00:00"
              },
              "planned_service_time_seconds": 14.5,
              "dimensions": {
                "depth_cm": 24.1,
                "height_cm": 3.6,
                "width_cm": 16.5
              }
            },
            "PackageID_844d116d-fba0-4567-94b6-d9a9b2158136": {
              "time_window": {
                "start_time_utc": "2018-08-14 14:00:00",
                "end_time_utc": "2018-08-14 21:00:00"
              },
              "planned_service_time_seconds": 14.5,
              "dimensions": {
                "depth_cm": 36.2,
                "height_cm": 27.9,
                "width_cm": 28.6
              }
            }
          }
        }
      }
      ```
    </details>


2. `new_route_data.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "station_code": "<station-code>",
        "date_YYYY_MM_DD": "<YYYY-MM-DD>",
        "departure_time_utc": "<hh:mm:ss>",
        "executor_capacity_cm3": "<uint32-number>",
        "stops": {
          "<stop-id>": {
            "lat": "<float-number>",
            "lng": "<float-number>",
            "type": "<stop-type>",
            "zone_id": "<zone-id>"
          },
          "..."
        }
      },
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": {
          "station_code": "DCH4",
          "date_YYYY_MM_DD": "2018-08-14",
          "departure_time_utc": "14:06:53",
          "executor_capacity_cm3": 4247527,
          "stops": {
            "AD": {
              "lat": 42.078681,
              "lng": -88.171583,
              "type": "Dropoff",
              "zone_id": "D-16.2C"
            },
            "AR": {
              "lat": 42.076736,
              "lng": -88.164158,
              "type": "Dropoff",
              "zone_id": "D-16.3D"
            }
          }
        },
        "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": {
          "station_code": "DLA7",
          "date_YYYY_MM_DD": "2018-08-09",
          "departure_time_utc": "16:07:13",
          "executor_capacity_cm3": 3313071,
          "stops": {
            "AC": {
              "lat": 34.119254,
              "lng": -117.614684,
              "type": "Dropoff",
              "zone_id": "G-25.2E"
            }
          }
        }
      }
      ```
    </details>


3. `new_travel_times.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "<stop-id*>": {
          "<stop-id*>": 0,
          "<stop-id>": "<float-number>",
          "<stop-id>": "<float-number>",
          "..."
        },
        "<stop-id*>": {
          "<stop-id>": "<float-number>",
          "<stop-id*>": 0,
          "<stop-id>": "<float-number>",
          "..."
        }
      }
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": {
          "AD": {
            "AD": 0,
            "AR": 225,
            "AX": 478.1,
          },
          "AR": {
            "AD": 251.9,
            "AR": 0,
            "AX": 424.6,
          }
        },
        "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": {
          "AC": {
            "AC": 0,
            "AH": 419.3,
          },
          "AH": {
            "AC": 443.2,
            "AH": 0
          }
        }
      }
      ```
    </details>

### `model_apply_outputs`:
1. `proposed_sequences.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "prediction": {
          "<stop-id>": 0,
          "<stop-id>": 1,
          "<stop-id>": 2,
          "<stop-id>": 3,
          "..."
        },
        "..."
      }
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": {
          "prediction": {
            "RY": 0,
            "QH": 1,
            "PY": 2,
            "NS": 3
          },
        },
        "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": {
          "prediction": {
            "SF": 0,
            "PT": 1,
            "LG": 2,
            "GU": 3
          }
        }
      }
      ```
    </details>

### `model_score_inputs`:
1. `new_actual_sequences.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": {
        "actual": {
          "<stop-id>": "<uint-number>",
          "..."
        }
      },
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": {
          "actual": {
            "AD": 44,
            "AR": 26,
            "AX": 4,
            "BA": 85
          }
        },
        "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": {
          "actual": {
            "AC": 62,
            "AH": 132
          }
        }
      }
      ```
    </details>


2. `new_invalid_sequence_scores.json`

    Data format:
    ```json
    {
      "RouteID_<hex-hash>": "<float-number>",
      "..."
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": 0.9012432765379605,
        "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": 0.7468055008554786
      }
      ```
    </details>

### `model_score_timings`:
1. `model_build_time.json`

    Data format:
    ```json
    {
      "time": "<uint-number>",
      "status": "<proc-status>"
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "time": 14030,
        "status": "success"
      }
      ```
    </details>


2. `model_apply_time.json`

    Data format:
    ```json
    {
      "time": "<uint-number>",
      "status": "<proc-status>"
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "time": 3920,
        "status": "success"
      }
      ```
    </details>

### `model_score_outputs`:
1. `scores.json`

    Data format:
    ```json
    {
      "submission_score": "<float-number>",
      "route_scores": {
        "RouteID_<hex-hash>": "<float-number>",
        "RouteID_<hex-hash>": "<float-number>",
        "..."
      },
      "route_feasibility": {
        "RouteID_<hex-hash>": "<bool-value>",
        "RouteID_<hex-hash>": "<bool-value>",
        "..."
      },
      "model_apply_time": "<uint-number>",
      "model_build_time": "<uint-number>"
    }
    ```

    <details>
      <summary>Example</summary>

      ```json
      {
        "submission_score": 0.6086179706085669,
        "route_scores": {
          "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": 0.9012432765379605,
          "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": 0.31599266467917336
        },
        "route_feasibility": {
          "RouteID_1a4903de-1a85-4bca-921a-f746c68fbf7a": false,
          "RouteID_1a4e2edf-3fde-409f-8bf6-f01ff98d5afa": true
        },
        "model_apply_time": 3920,
        "model_build_time": 14030
      }
      ```
    </details>
