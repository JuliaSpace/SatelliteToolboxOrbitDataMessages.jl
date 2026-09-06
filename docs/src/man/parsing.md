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

This package parses Orbit Data Messages provided as strings in the **XML** and **KVN**
(Key-Value Notation) formats. The format is detected automatically from the content, or it
can be selected explicitly with the `format` keyword (`:auto`, `:xml`, or `:kvn`) of
[`parse_omm`](@ref), [`parse_omms`](@ref), and [`parse_odm`](@ref).

The parsers accommodate the deviations commonly found in real-world files: the XML tags and
the OMM `id` attribute value are matched ignoring the case, empty XML elements are treated
as absent fields, and a missing `CREATION_DATE` is preserved as `nothing`, which
accommodates known Celestrak OMM 2.0 output without inventing a timestamp. Additionally, a
blank `ORIGINATOR` is allowed in OMM version 2.0, defaulting to an empty string. Such
incomplete messages cannot be written as OMM 3.0. Unrecognized tags and malformed or
incomplete OMM sections are rejected by throwing an [`OdmParseError`](@ref), which carries
the related CCSDS keyword and, for KVN input, the line number.

Throughout this page, we assume the variable `omm_xml` holds the XML string of a single OMM,
and `ndm_xml` holds a Navigation Data Message (NDM) that bundles two OMMs (`AMAZONIA 1` and
`SCD 1`).

## Parsing a Single OMM

Use [`parse_omm`](@ref) to obtain a single [`OrbitMeanElementsMessage`](@ref). If the input
is an NDM containing several OMMs, only the **first** one is returned:

```@repl parsing
omm = parse_omm(omm_xml)
```

If the input does not contain any OMM, the function throws an [`OdmParseError`](@ref).

## Parsing Multiple OMMs

When a document may contain several messages — as is typically the case with an NDM — use
[`parse_omms`](@ref) to retrieve **all** OMMs as a vector:

```@repl parsing
omms = parse_omms(ndm_xml)

length(omms)

omms[2].metadata.object_name
```

`parse_omms` always returns a `Vector{OrbitMeanElementsMessage}`, which is empty when a
recognized document contains no supported OMM.

## Parsing Generic Orbit Data Messages

The [`parse_odm`](@ref) function is the most general entry point. For XML input, it
inspects the root tag of the document and dispatches to the appropriate parser:

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

## Parsing KVN Messages

[`parse_omm`](@ref) and [`parse_omms`](@ref) also understand the KVN format, in which each
field is written as a `KEYWORD = value` line:

```@repl parsing
omm_kvn = """
CCSDS_OMM_VERS      = 3.0
COMMENT Generated by SatelliteToolboxOrbitDataMessages.jl
CREATION_DATE       = 2025-12-30T23:36:37
ORIGINATOR          = 18 SPCS

OBJECT_NAME         = AMAZONIA 1
OBJECT_ID           = 2021-015A
CENTER_NAME         = EARTH
REF_FRAME           = TEME
TIME_SYSTEM         = UTC
MEAN_ELEMENT_THEORY = SGP4

EPOCH               = 2025-12-30T18:12:04.533984
MEAN_MOTION         = 14.40772474     [rev/day]
ECCENTRICITY        = 0.0001124
INCLINATION         = 98.3721         [deg]
RA_OF_ASC_NODE      = 75.0877         [deg]
ARG_OF_PERICENTER   = 97.3772         [deg]
MEAN_ANOMALY        = 262.7545        [deg]
""";

omm = parse_omm(omm_kvn)
```

The format is inferred automatically: input starting with an XML tag is parsed as XML, and
anything else as KVN. Pass `format = :xml` or `format = :kvn` to skip the detection.

The KVN parser preserves the `COMMENT` lines, attributing each one to the section of the
keyword that follows it, and reads user-defined parameters from keywords with the
`USER_DEFINED_` prefix. Since the CCSDS standard does not define a KVN container for
multiple messages, [`parse_omms`](@ref) assumes each message starts at its
`CCSDS_OMM_VERS` keyword:

```@repl parsing
omms = parse_omms(omm_kvn ^ 2)

length(omms)
```
