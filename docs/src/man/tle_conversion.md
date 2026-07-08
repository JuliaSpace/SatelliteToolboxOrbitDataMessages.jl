# [Converting to TLE](@id Converting-to-TLE)

```@meta
CurrentModule = SatelliteToolboxOrbitDataMessages
```

```@setup tle
using SatelliteToolboxOrbitDataMessages
using NanoDates

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
    norad_cat_id        = 47699,
    classification_type = 'U',
    element_set_number  = 999,
    rev_at_epoch        = 25439,
    bstar               = 0.0001533,
    mean_motion_dot     = 0.00000447,
    mean_motion_ddot    = 0.0,
)
```

Orbit Mean-Elements Messages whose mean elements follow the **SGP4** theory can be converted
into a classic [Two-Line Element set
(TLE)](https://en.wikipedia.org/wiki/Two-line_element_set). This is useful to interoperate
with the many tools in the SatelliteToolbox.jl ecosystem that consume TLEs, such as the SGP4
propagator.

This capability is provided by a **package extension** that is loaded automatically once
[SatelliteToolboxTle.jl](https://github.com/JuliaSpace/SatelliteToolboxTle.jl) is available
in your environment:

```julia
julia> using Pkg

julia> Pkg.add("SatelliteToolboxTle")
```

## Performing the Conversion

Load both packages and use Julia's `convert` function with the target type `TLE`. Assuming
the variable `omm` holds an [`OrbitMeanElementsMessage`](@ref) for the Amazonia 1 satellite:

```@repl tle
using SatelliteToolboxTle

tle = convert(TLE, omm)
```

The conversion maps the OMM fields to their TLE counterparts, including the translation of
the `OBJECT_ID` (e.g. `2021-015A`) into the TLE international designator format (e.g.
`21015A`).

## Requirements and Behavior

- **Mean element theory.** The conversion only succeeds when the metadata field
  `mean_element_theory` is equal to `"SGP4"`. Otherwise, an error is raised, since the
  elements cannot be interpreted as a TLE.

- **Mean motion.** TLEs are expressed in terms of the mean motion. If the OMM provides
  `mean_motion` directly, it is used as is. If only the `semi_major_axis` is available, the
  mean motion is computed from it, which additionally requires the gravitational parameter
  `GM` to be present:

  ```math
  n = \frac{1}{2\pi}\sqrt{\frac{GM}{a^3}} \times 86400
  ```

- **Optional fields.** Fields that are absent in the OMM (such as `bstar`,
  `mean_motion_dot`, `norad_cat_id`, or `rev_at_epoch`) default to zero or to the standard
  TLE placeholder values during the conversion.

!!! warning

    The CCSDS standard does not fully specify whether the derivative fields
    (`MEAN_MOTION_DOT` and `MEAN_MOTION_DDOT`) already incorporate the SGP4 scaling factors.
    Based on the data returned by Celestrak and Space-Track, this package assumes they are
    already adjusted and copies them directly into the TLE.
