# Data structures
## Introduction
Data is at the very heart of your project. In order for you to correctly parse the input files in your program and generate the correct format for the output files in each phase (`model-build` and `model-apply`), you must become familiar with the input and output data structures.

In this document we will describe the contents of each folder included in the `data` folder.

## `data/`
### `model_build_inputs`:
1. `actual_sequences.json`:

    Data format:
    ```json

    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


2. `invalid_sequence_scores.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


3. `package_data.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


4. `route_data.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


5. `travel_times.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


### `model_build_outputs`:
#### TODO: Depict or describe the format of these output files.

### `model_apply_inputs`:
1. `new_package_data.json`

    Data format:
    ```json
    {
      "<RouteID_<hex-hash>": {
        "<state-abbrev>": {
          "PackageID_<hex-hash>": {
            "time_window": {
              "start_time_utc": "<YYYY-MM-DD hh:mm:ss>",
              "end_time_utc": "<YYYY-MM-DD hh:mm:ss>"
            },
            "planned_service_time_seconds": <int-number>,
            "dimensions": {
              "depth_cm": <float-number>,
              "height_cm": <float-number>,
              "width_cm": <float-number>
            }
          },
          "PackageID_<hex-hash>": {
            ...
          },
          ...
        },
        "<state-abbrev>": {
          ...
        },
        ...
      },
      "<RouteID_<hex-hash>": {
        ...
      },
      ...
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
          },
          ...,
          "ZT": {...}
        }
      }
      ```
    </details>


2. `new_route_data.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


3. `new_travel_times.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>

### `model_apply_outputs`:
1. `proposed_sequences.json`

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>

### `model_score_inputs`:
1. `new_actual_sequences.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


2. `new_invalid_sequence_scores.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>

### `model_score_timings`:

1. `model_build_time.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>


2. `model_apply_time.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>

### `model_score_outputs`:

1. `scores.json`:

    Data format:
    ```json
    ```

    <details>
      <summary>Example</summary>

      ```json
      ```
    </details>
