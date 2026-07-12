<p align="center">
  <img src="./docs/src/assets/logo.png" width="150" title="SatelliteToolboxOrbitDataMessages.jl"><br>
  <small><i>This package is part of the <a href="https://github.com/JuliaSpace/SatelliteToolbox.jl">SatelliteToolbox.jl</a> ecosystem.</i></small>
</p>

# SatelliteToolboxOrbitDataMessages.jl

[![CI](https://img.shields.io/github/actions/workflow/status/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl/ci.yml?style=flat-square&logo=githubactions&logoColor=white&labelColor=475569&label=CI)](https://github.com/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl/actions/workflows/ci.yml)
[![Codecov](https://img.shields.io/codecov/c/github/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl?token=IQMHCB4OB7&style=flat-square&logo=codecov&logoColor=white&labelColor=475569)](https://codecov.io/gh/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl)
[![docs-stable](https://img.shields.io/badge/docs-stable-16A34A?style=flat-square&logo=gitbook&logoColor=white&labelColor=475569)](https://juliaspace.github.io/SatelliteToolboxOrbitDataMessages.jl/stable)
[![docs-dev](https://img.shields.io/badge/docs-dev-D97706?style=flat-square&logo=gitbook&logoColor=white&labelColor=475569)](https://juliaspace.github.io/SatelliteToolboxOrbitDataMessages.jl/dev)
[![License](https://img.shields.io/github/license/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl?style=flat-square&logo=readme&logoColor=white&labelColor=475569&color=0284C7)](https://github.com/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl/blob/main/LICENSE)
<!--[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.XXXXXXX-DB2777?style=flat-square&logo=doi&logoColor=white&labelColor=475569)](https://zenodo.org/doi/10.5281/zenodo.XXXXXXX)-->

This package allows creating, fetching, and parsing Orbit Data Messages (ODM) as described
in the [CCSDS 502.0-B-3 standard](https://ccsds.org/Pubs/502x0b3e1.pdf).

We currently support only parsing and fetching ODM files in the XML format with the
following message types:

- `OMM`: Orbit Mean-Elements Message.
- `NDM`: Navigation Data Message.

## Installation

This package can be installed using:

``` julia
julia> using Pkg
julia> Pkg.add("SatelliteToolboxOrbitDataMessages")
```

## Documentation

For more information, see the [documentation][docs-stable-url].

[docs-dev-url]: https://juliaspace.github.io/SatelliteToolboxOrbitDataMessages.jl/dev
[docs-stable-url]: https://juliaspace.github.io/SatelliteToolboxOrbitDataMessages.jl/stable
