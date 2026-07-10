# [Reading and Writing Files](@id Reading-and-Writing-Files)

```@meta
CurrentModule = SatelliteToolboxOrbitDataMessages
```

```@setup rw
using SatelliteToolboxOrbitDataMessages
using NanoDates

# Create a sample CCSDS-compliant OMM file to be used in the reading examples.
sample_xml = """
<?xml version="1.0" encoding="utf-8"?>
<ndm><omm id="CCSDS_OMM_VERS" version="3.0"><header><COMMENT>GENERATED VIA SPACE-TRACK.ORG API</COMMENT><CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE><ORIGINATOR>18 SPCS</ORIGINATOR></header><body><segment><metadata><OBJECT_NAME>AMAZONIA 1</OBJECT_NAME><OBJECT_ID>2021-015A</OBJECT_ID><CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME><TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY></metadata><data><meanElements><EPOCH>2025-12-30T18:12:04.533984</EPOCH><MEAN_MOTION>14.40772474</MEAN_MOTION><ECCENTRICITY>0.00011240</ECCENTRICITY><INCLINATION>98.3721</INCLINATION><RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE><ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER><MEAN_ANOMALY>262.7545</MEAN_ANOMALY></meanElements></data></segment></body></omm></ndm>
"""

sample_file = tempname() * ".xml"
write(sample_file, sample_xml)
```

Besides working with XML strings directly (see [Parsing Messages](@ref Parsing-Messages)),
this package can read messages from files on disk and serialize them back to the XML format
defined by CCSDS 502.0-B-3.

## Reading From a File

Assume the variable `sample_file` holds the path to an XML file containing a
CCSDS-compliant OMM. We can load it with [`read_omm`](@ref):

```@repl rw
omm = read_omm(sample_file)
```

To read a generic Orbit Data Message — which may be a single message or a Navigation Data
Message (NDM) bundling several messages — use [`read_odm`](@ref):

```@repl rw
odm = read_odm(sample_file)
```

Both functions simply read the file contents and forward them to the corresponding parsing
function, so the return values follow the same rules described in
[Parsing Messages](@ref Parsing-Messages).

## Writing to a File

Given an [`OrbitMeanElementsMessage`](@ref) object, we can serialize it to XML using
[`write_omm`](@ref). The function receives an `IO` stream, which makes it easy to write to a
file or inspect the output in memory:

```@repl rw
io = IOBuffer();

write_omm(io, omm)

print(String(take!(io)))
```

To write directly to a file, open the file in write mode and pass the stream:

```julia
open("amazonia_1.xml", "w") do io
    write_omm(io, omm)
end
```

## Writing Several Messages as an NDM

The [`write_odm`](@ref) function can serialize either a single message or a **vector** of
messages. When a vector is provided, all messages are wrapped inside a single Navigation
Data Message (`<ndm>`) root element:

```julia
omms = [omm1, omm2, omm3]

open("catalog.xml", "w") do io
    write_odm(io, omms)
end
```

This is convenient, for example, to persist the full set of messages returned by one of the
[online fetchers](@ref Fetching-from-Services).

!!! note

    OMM elements are always written with version `3.0`, regardless of the version stored in
    the parsed message, and target the NDM/XML schema. `NanoDate` values are written with
    nine fractional digits, preserving nanosecond precision. Optional sections (spacecraft
    parameters, TLE-related parameters, and user-defined parameters) are only written when
    the corresponding fields are present in the message.
