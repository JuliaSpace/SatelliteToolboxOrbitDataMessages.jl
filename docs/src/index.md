# SatelliteToolboxOrbitDataMessages.jl

This package allows creating, fetching, parsing, and writing **Orbit Data Messages (ODM)**
as described in the [CCSDS 502.0-B-3 standard](https://ccsds.org/Pubs/502x0b3e1.pdf). It is
part of the [SatelliteToolbox.jl](https://github.com/JuliaSpace/SatelliteToolbox.jl)
ecosystem.

The Orbit Data Messages standard defines a set of message types to exchange orbit
information between space agencies, operators, and applications. This package currently
supports the following message types in the **XML** format:

| **Message**                          | **Abbreviation** | **Status**              |
|:-------------------------------------|:-----------------|:------------------------|
| Orbit Mean-Elements Message          | `OMM`            | Read / Write / Fetch    |
| Navigation Data Message              | `NDM`            | Read / Write (OMM only) |
| Orbit Parameter Message              | `OPM`            | Not supported yet       |
| Orbit Ephemeris Message              | `OEM`            | Not supported yet       |
| Orbit Comprehensive Message          | `OCM`            | Not supported yet       |

With this package you can:

- Build an [`OrbitMeanElementsMessage`](@ref) from scratch using a keyword constructor;
- Parse OMMs and NDMs from XML strings or files;
- Write OMMs and NDMs to XML files;
- Fetch the latest orbit data directly from the [Celestrak](https://celestrak.org) and
  [Space-Track](https://www.space-track.org) services; and
- Convert an OMM into a
  [TLE](https://en.wikipedia.org/wiki/Two-line_element_set) (requires
  [SatelliteToolboxTle.jl](https://github.com/JuliaSpace/SatelliteToolboxTle.jl)).

## Installation

```julia
julia> using Pkg
julia> Pkg.add("SatelliteToolboxOrbitDataMessages")
```

## Manual Outline

```@contents
Pages = [
    "man/quick_start.md",
    "man/creating_omms.md",
    "man/parsing.md",
    "man/reading_writing.md",
    "man/fetching.md",
    "man/tle_conversion.md",
]
Depth = 1
```
