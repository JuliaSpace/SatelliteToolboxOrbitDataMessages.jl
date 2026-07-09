# [Creating OMMs](@id Creating-OMMs)

```@meta
CurrentModule = SatelliteToolboxOrbitDataMessages
```

```@setup creating
using SatelliteToolboxOrbitDataMessages
using NanoDates
```

An Orbit Mean-Elements Message (OMM) is represented by the
[`OrbitMeanElementsMessage`](@ref) type. Although this structure follows the nested
hierarchy defined by the CCSDS standard (header, metadata, and data), we can create a
complete message using a single **keyword constructor**. It takes care of assembling the
internal sections for us.

```julia
OrbitMeanElementsMessage(; kwargs...) -> OrbitMeanElementsMessage
```

## Date Fields

The fields `creation_date`, `epoch`, and `ref_frame_epoch` must be provided as
[`NanoDate`](https://github.com/JeffreySarnoff/NanoDates.jl) objects so that the message can
retain the sub-second precision usually present in orbit data. We can build a `NanoDate`
from a string or from a `Dates.DateTime`:

```@repl creating
using NanoDates

NanoDate("2025-12-30T18:12:04.533984")

NanoDate(DateTime(2025, 12, 30, 18, 12, 4))
```

## Minimal Example

The keyword constructor requires the mandatory fields defined by the standard: the message
originator, the object identification, the reference frame and time system, and the mean
Keplerian elements. The following example creates the OMM for the
[Amazonia 1](https://en.wikipedia.org/wiki/Amazonia-1) satellite:

```@repl creating
omm = OrbitMeanElementsMessage(;
    # == Header ========================================================
    creation_date       = NanoDate("2025-12-30T23:36:37"),
    originator          = "18 SPCS",

    # == Metadata ======================================================
    object_name         = "AMAZONIA 1",
    object_id           = "2021-015A",
    center_name         = "EARTH",
    ref_frame           = "TEME",
    time_system         = "UTC",
    mean_element_theory = "SGP4",

    # == Mean Keplerian Elements =======================================
    epoch               = NanoDate("2025-12-30T18:12:04.533984"),
    mean_motion         = 14.40772474,
    eccentricity        = 0.00011240,
    inclination         = 98.3721,
    raan                = 75.0877,
    arg_of_pericenter   = 97.3772,
    mean_anomaly        = 262.7545,
)
```

!!! note

    The mean elements section requires **either** `mean_motion` **or** `semi_major_axis`.
    All angular quantities (`inclination`, `raan`, `arg_of_pericenter`, and `mean_anomaly`)
    are expressed in **degrees**, following the CCSDS 502.0-B-3 convention.

## Adding Optional Sections

The OMM standard defines several optional sections. They can be populated by passing the
corresponding keywords. For example, we can add the TLE-related parameters and some
spacecraft data:

```@repl creating
omm = OrbitMeanElementsMessage(;
    creation_date       = NanoDate("2025-12-30T23:36:37"),
    originator          = "18 SPCS",
    object_name         = "AMAZONIA 1",
    object_id           = "2021-015A",
    center_name         = "EARTH",
    ref_frame           = "TEME",
    time_system         = "UTC",
    mean_element_theory = "SGP4",
    epoch               = NanoDate("2025-12-30T18:12:04.533984"),
    mean_motion         = 14.40772474,
    eccentricity        = 0.00011240,
    inclination         = 98.3721,
    raan                = 75.0877,
    arg_of_pericenter   = 97.3772,
    mean_anomaly        = 262.7545,

    # == Spacecraft Data ===============================================
    mass                = 640.0,
    drag_area           = 8.5,
    drag_coeff          = 2.2,

    # == TLE-Related Parameters ========================================
    norad_cat_id        = 47699,
    classification_type = 'U',
    element_set_number  = 999,
    rev_at_epoch        = 25439,
    bstar               = 0.0001533,
    mean_motion_dot     = 0.00000447,
    mean_motion_ddot    = 0.0,

    # == User-Defined Parameters =======================================
    user_defined_parameters = [
        "COUNTRY_CODE" => "BRAZ",
        "LAUNCH_DATE"  => "2021-02-28",
    ],
)
```

## Copying and Modifying a Message

Since `OrbitMeanElementsMessage` is immutable, we can create a modified copy of an existing
message by passing it to the constructor together with the keywords we want to override. The
remaining fields are copied from the original message:

```@repl creating
new_omm = OrbitMeanElementsMessage(omm; originator = "SATELLITE TOOLBOX")

new_omm.header.originator
```

## Available Keywords

The following table lists all keywords accepted by the constructor. Fields marked as
**required** must always be provided.

| **Keyword**                | **Type**                          | **Section**       | **Required** |
|:---------------------------|:----------------------------------|:------------------|:------------:|
| `header_comment`           | `String`                          | Header            |              |
| `classification`           | `String`                          | Header            |              |
| `creation_date`            | `NanoDate`                        | Header            |      ✅       |
| `originator`               | `String`                          | Header            |      ✅       |
| `message_id`               | `String`                          | Header            |              |
| `metadata_comment`         | `String`                          | Metadata          |              |
| `object_name`              | `String`                          | Metadata          |      ✅       |
| `object_id`                | `String`                          | Metadata          |      ✅       |
| `center_name`              | `String`                          | Metadata          |      ✅       |
| `ref_frame`                | `String`                          | Metadata          |      ✅       |
| `ref_frame_epoch`          | `NanoDate`                        | Metadata          |              |
| `time_system`              | `String`                          | Metadata          |      ✅       |
| `mean_element_theory`      | `String`                          | Metadata          |      ✅       |
| `data_comment`             | `String`                          | Mean Elements     |              |
| `epoch`                    | `NanoDate`                        | Mean Elements     |      ✅       |
| `semi_major_axis`          | `Float64`                         | Mean Elements     |    ✅ [^1]    |
| `mean_motion`              | `Float64`                         | Mean Elements     |    ✅ [^1]    |
| `eccentricity`             | `Float64`                         | Mean Elements     |      ✅       |
| `inclination`              | `Float64`                         | Mean Elements     |      ✅       |
| `raan`                     | `Float64`                         | Mean Elements     |      ✅       |
| `arg_of_pericenter`        | `Float64`                         | Mean Elements     |      ✅       |
| `mean_anomaly`             | `Float64`                         | Mean Elements     |      ✅       |
| `GM`                       | `Float64`                         | Mean Elements     |              |
| `spacecraft_data_comment`  | `String`                          | Spacecraft Data   |              |
| `mass`                     | `Float64`                         | Spacecraft Data   |              |
| `solar_rad_area`           | `Float64`                         | Spacecraft Data   |              |
| `solar_rad_coeff`          | `Float64`                         | Spacecraft Data   |              |
| `drag_area`                | `Float64`                         | Spacecraft Data   |              |
| `drag_coeff`               | `Float64`                         | Spacecraft Data   |              |
| `tle_parameters_comment`   | `String`                          | TLE Parameters    |              |
| `ephemeris_type`           | `Int`                             | TLE Parameters    |              |
| `classification_type`      | `Char`                            | TLE Parameters    |              |
| `norad_cat_id`             | `Int`                             | TLE Parameters    |              |
| `element_set_number`       | `Int`                             | TLE Parameters    |              |
| `rev_at_epoch`             | `Int`                             | TLE Parameters    |              |
| `bstar`                    | `Float64`                         | TLE Parameters    |              |
| `mean_motion_dot`          | `Float64`                         | TLE Parameters    |              |
| `mean_motion_ddot`         | `Float64`                         | TLE Parameters    |              |
| `covariance_matrix`        | `OmmCovarianceMatrix`             | Covariance Matrix |              |
| `user_defined_parameters`  | `Vector{Pair{String, String}}`    | User-Defined      |              |

[^1]: At least one of `semi_major_axis` or `mean_motion` must be provided.

## Covariance Matrix

The OMM standard defines an optional covariance matrix section. It is represented by the
`OmmCovarianceMatrix` type, which stores the 21 unique upper-triangular elements of the
symmetric 6×6 matrix, along with an optional comment and reference frame:

```@repl creating
cov = OmmCovarianceMatrix(;
    cov_ref_frame = "ITRF",
    cx_x           = 1.0,
    cy_x           = 2.0,
    cy_y           = 3.0,
    cz_x           = 4.0,
    cz_y           = 5.0,
    cz_z           = 6.0,
    cx_dot_x       = 7.0,
    cx_dot_y       = 8.0,
    cx_dot_z       = 9.0,
    cx_dot_x_dot   = 10.0,
    cy_dot_x       = 11.0,
    cy_dot_y       = 12.0,
    cy_dot_z       = 13.0,
    cy_dot_x_dot   = 14.0,
    cy_dot_y_dot   = 15.0,
    cz_dot_x       = 16.0,
    cz_dot_y       = 17.0,
    cz_dot_z       = 18.0,
    cz_dot_x_dot   = 19.0,
    cz_dot_y_dot   = 20.0,
    cz_dot_z_dot   = 21.0,
)

omm = OrbitMeanElementsMessage(omm; covariance_matrix = cov)

omm.body.segment.data.covariance_matrix.cov_ref_frame
```
