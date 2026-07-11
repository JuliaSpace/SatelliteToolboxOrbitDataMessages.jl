# [Parsing Messages](@id Parsing-Messages)

```@meta
CurrentModule = SatelliteToolboxOrbitDataMessages
```

```@setup parsing
using SatelliteToolboxOrbitDataMessages

omm_xml = """
<?xml version="1.0" encoding="utf-8"?>
<ndm xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><omm id="CCSDS_OMM_VERS" version="3.0"><header><COMMENT>GENERATED VIA SPACE-TRACK.ORG API</COMMENT><CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE><ORIGINATOR>18 SPCS</ORIGINATOR></header><body><segment><metadata><OBJECT_NAME>AMAZONIA 1</OBJECT_NAME><OBJECT_ID>2021-015A</OBJECT_ID><CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME><TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY></metadata><data><meanElements><EPOCH>2025-12-30T18:12:04.533984</EPOCH><MEAN_MOTION>14.40772474</MEAN_MOTION><ECCENTRICITY>0.00011240</ECCENTRICITY><INCLINATION>98.3721</INCLINATION><RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE><ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER><MEAN_ANOMALY>262.7545</MEAN_ANOMALY></meanElements></data></segment></body></omm></ndm>
"""

ndm_xml = """
<?xml version="1.0" encoding="utf-8"?>
<ndm xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><omm id="CCSDS_OMM_VERS" version="3.0"><header><CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE><ORIGINATOR>18 SPCS</ORIGINATOR></header><body><segment><metadata><OBJECT_NAME>AMAZONIA 1</OBJECT_NAME><OBJECT_ID>2021-015A</OBJECT_ID><CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME><TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY></metadata><data><meanElements><EPOCH>2025-12-30T18:12:04.533984</EPOCH><MEAN_MOTION>14.40772474</MEAN_MOTION><ECCENTRICITY>0.00011240</ECCENTRICITY><INCLINATION>98.3721</INCLINATION><RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE><ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER><MEAN_ANOMALY>262.7545</MEAN_ANOMALY></meanElements></data></segment></body></omm><omm id="CCSDS_OMM_VERS" version="3.0"><header><CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE><ORIGINATOR>18 SPCS</ORIGINATOR></header><body><segment><metadata><OBJECT_NAME>SCD 1</OBJECT_NAME><OBJECT_ID>1993-009B</OBJECT_ID><CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME><TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY></metadata><data><meanElements><EPOCH>2025-12-30T20:30:29.736576</EPOCH><MEAN_MOTION>14.42978855</MEAN_MOTION><ECCENTRICITY>0.00301990</ECCENTRICITY><INCLINATION>24.9690</INCLINATION><RA_OF_ASC_NODE>84.2698</RA_OF_ASC_NODE><ARG_OF_PERICENTER>92.8244</ARG_OF_PERICENTER><MEAN_ANOMALY>267.6017</MEAN_ANOMALY></meanElements></data></segment></body></omm></ndm>
"""
```

This package parses Orbit Data Messages provided as **XML** strings. All parsing functions
accept either a raw XML `AbstractString` or an already-parsed
[`XML.LazyNode`](https://github.com/JuliaComputing/XML.jl) object.

Parsing is strict and case-sensitive by default. Pass `strict = false` to `parse_omm`,
`parse_omms`, or `parse_odm` to match XML tags and the required OMM `id` attribute value
case-insensitively. Permissive mode also preserves an empty OMM header creation date as
`nothing`, which accommodates known Celestrak OMM 2.0 output without inventing a timestamp.
Such an incomplete message cannot be written as OMM 3.0. Both modes otherwise reject
unrecognized tags and malformed or incomplete OMM sections.

Throughout this page, we assume the variable `omm_xml` holds the XML string of a single OMM,
and `ndm_xml` holds a Navigation Data Message (NDM) that bundles two OMMs (`AMAZONIA 1` and
`SCD 1`).

## Parsing a Single OMM

Use [`parse_omm`](@ref) to obtain a single [`OrbitMeanElementsMessage`](@ref). If the input
is an NDM containing several OMMs, only the **first** one is returned:

```@repl parsing
omm = parse_omm(omm_xml)
```

If the input does not contain any OMM, the function returns `nothing`.

## Parsing Multiple OMMs

When a document may contain several messages — as is typically the case with an NDM — use
[`parse_omms`](@ref) to retrieve **all** OMMs as a vector:

```@repl parsing
omms = parse_omms(ndm_xml)

length(omms)

omms[2].body.segment.metadata.object_name
```

`parse_omms` always returns a `Vector{OrbitMeanElementsMessage}`, which is empty when a
recognized document contains no supported OMM.

## Parsing Generic Orbit Data Messages

The [`parse_odm`](@ref) function is the most general entry point. It inspects the root tag
of the document and dispatches to the appropriate parser:

`parse_odm` always returns a `Vector{OrbitDataMessage}`. A stand-alone `<omm>` produces a
single-element vector, while an `<ndm>` produces a vector containing every supported message.

```@repl parsing
odm = parse_odm(omm_xml)

odms = parse_odm(ndm_xml)
```

!!! note

    Only OMM messages are currently extracted. Other message types found inside an NDM
    (such as `OPM`, `OEM`, or `OCM`) are skipped with a warning, since they are not yet
    supported.

## Working With `LazyNode` Directly

If you already have an `XML.LazyNode` — for instance, because you are traversing a larger
document — you can pass it directly to any of the parsing functions:

```julia
using XML

xml = parse(omm_xml, LazyNode)
omm = parse_omm(xml)
```
