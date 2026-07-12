<p align="center">
  <img src="./docs/src/assets/logo.png" width="150" title="SatelliteToolboxOrbitDataMessages.jl"><br>
  <small><i>This package is part of the <a href="https://github.com/JuliaSpace/SatelliteToolbox.jl">SatelliteToolbox.jl</a> ecosystem.</i></small>
</p>

# SatelliteToolboxOrbitDataMessages.jl

[![CI](https://github.com/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl/graph/badge.svg?token=IQMHCB4OB7)](https://codecov.io/gh/JuliaSpace/SatelliteToolboxOrbitDataMessages.jl)
[![docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)][docs-stable-url]
[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)][docs-dev-url]

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
