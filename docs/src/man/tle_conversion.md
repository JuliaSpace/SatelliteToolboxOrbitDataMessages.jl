# [Converting to and from TLE](@id Converting-to-TLE)

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
(TLE)](https://en.wikipedia.org/wiki/Two-line_element_set), and TLEs can be converted into
Orbit Mean-Elements Messages. This is useful to interoperate with the many tools in the
SatelliteToolbox.jl ecosystem that consume TLEs, such as the SGP4 propagator, and to
distribute TLEs in the CCSDS formats.

This capability is provided by a **package extension** that is loaded automatically once
[SatelliteToolboxTle.jl](https://github.com/JuliaSpace/SatelliteToolboxTle.jl) (version 2 or
newer) is available in your environment:

```julia
julia> using Pkg

julia> Pkg.add("SatelliteToolboxTle")
```

## Converting an OMM to a TLE

Load both packages and use Julia's `convert` function with the target type `TLE`. Assuming
the variable `omm` holds an [`OrbitMeanElementsMessage`](@ref) for the Amazonia 1 satellite:

```@repl tle
using SatelliteToolboxTle

tle = convert(TLE, omm)
```

The conversion maps the OMM fields to their TLE counterparts, including the translation of
the `OBJECT_ID` (e.g. `2021-015A`) into the TLE international designator format (e.g.
`21015A`).

### Requirements and Behavior

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

- **Required TLE fields.** Conversion requires `classification_type`, `norad_cat_id`,
  `element_set_number`, `rev_at_epoch`, `bstar`, `mean_motion_dot`, and
  `mean_motion_ddot`. Missing fields raise an error; they do not receive placeholder values.
  The optional `ephemeris_type` is copied when present and defaults to 0 otherwise.
- **Unsupported alternatives.** OMM TLE parameters may represent drag with either `bstar` or
  `bterm`, and the second derivative slot with either `mean_motion_ddot` or `agom`. A classic
  TLE conversion requires `bstar` and `mean_motion_ddot`; conversion rejects `bterm` and
  `agom` because they have no direct TLE representation.
- **Epoch.** The two-digit TLE year can only represent the years from 1957 to 2056, so an
  epoch outside this interval raises an error. The day fraction keeps the sub-millisecond
  precision of the message epoch.

!!! warning

    The CCSDS standard does not fully specify whether the derivative fields
    (`MEAN_MOTION_DOT` and `MEAN_MOTION_DDOT`) already incorporate the SGP4 scaling factors.
    Based on the data returned by Celestrak and Space-Track, this package assumes they are
    already adjusted and copies them directly into the TLE.

## Converting a TLE to an OMM

The opposite direction is provided by the constructor
`OrbitMeanElementsMessage(tle; kwargs...)`, which accepts any keyword of the keyword
constructor `OrbitMeanElementsMessage(; kwargs...)` (see [Creating OMMs](@ref
Creating-OMMs)) to override the generated fields. Julia's `convert` can also be used, in
which case the message receives the default header:

```@repl tle
omm_from_tle = OrbitMeanElementsMessage(tle; originator = "MY AGENCY")

convert(OrbitMeanElementsMessage, tle) isa OrbitMeanElementsMessage
```

The mean Keplerian elements and the TLE-related parameters are copied from the TLE, and the
metadata describes the conventions of the TLE format: the center name is `"EARTH"`, the
reference frame is `"TEME"`, the time system is `"UTC"`, and the mean element theory is
`"SGP4"`. The international designator (e.g. `21015A`) is translated back to the `OBJECT_ID`
format (e.g. `2021-015A`); a designator that does not follow the TLE format is copied as is.

The TLE has no header information, so the message receives the current UTC time as
`creation_date` and this package as `originator`, which are the fields most likely to be
overridden with the keywords. The header `classification` and the `message_id` are left
unset.

!!! note

    The two-digit years of the TLE epoch and of the international designator are interpreted
    as in the SGP4 reference implementation: years from 57 to 99 refer to the 20th century,
    and years from 0 to 56 to the 21st century. The epoch is rounded to the microsecond,
    which is far below the resolution of the TLE epoch field (0.864 ms) and matches the
    precision of the messages distributed by Celestrak and Space-Track.
