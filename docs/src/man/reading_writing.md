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

Besides working with strings directly (see [Parsing Messages](@ref Parsing-Messages)),
this package can read messages from files on disk and serialize them back to the XML and
KVN formats defined by CCSDS 502.0-B-3.

## Reading From a File

Assume the variable `sample_file` holds the path to a file containing a CCSDS-compliant
OMM, in either the XML or the KVN format. We can load it with [`read_omm`](@ref):

```@repl rw
omm = read_omm(sample_file)
```

If the file may contain several messages, use [`read_omms`](@ref) to retrieve all OMMs as
a vector:

```@repl rw
omms = read_omms(sample_file)
```

To read a generic Orbit Data Message — which may be a single message or a Navigation Data
Message (NDM) bundling several messages — use [`read_odm`](@ref):

```@repl rw
odm = read_odm(sample_file)
```

All functions simply read the file contents and forward them to the corresponding parsing
function, so the input format is detected automatically and the return values follow the
same rules described in [Parsing Messages](@ref Parsing-Messages).

## Writing to a File

Given an [`OrbitMeanElementsMessage`](@ref) object, we can serialize it with
[`write_omm`](@ref). The function accepts a file path, inferring the output format from
the extension (case-insensitive): `.kvn` selects the KVN format, whereas any other
extension selects the XML format. The `format` keyword (`:auto`, `:xml`, or `:kvn`)
overrides the inference:

```julia
write_omm("amazonia_1.xml", omm)                    # XML output.
write_omm("amazonia_1.kvn", omm)                    # KVN output.
write_omm("amazonia_1.omm", omm; format = :kvn)  # KVN output with another extension.
```

The function also receives an `IO` stream, which makes it easy to inspect the output in
memory. In this case, the default output format is XML:

```@repl rw
io = IOBuffer();

write_omm(io, omm)

print(String(take!(io)))
```

The same message in the KVN format:

```@repl rw
write_omm(io, omm; format = :kvn)

print(String(take!(io)))
```

## Writing Several Messages

[`write_omm`](@ref) also accepts a **vector** of messages. In the XML format, all messages
are wrapped inside a single Navigation Data Message (`<ndm>`) root element, whereas in the
KVN format they are written sequentially, each one starting at its `CCSDS_OMM_VERS`
keyword:

```julia
omms = [omm1, omm2, omm3]

write_omm("catalog.xml", omms)
write_omm("catalog.kvn", omms)
```

The [`write_odm`](@ref) function provides the same functionality for generic Orbit Data
Messages, accepting the same `format` keyword:

```julia
write_odm("catalog.xml", omms)
write_odm("catalog.kvn", omms)
```

This is convenient, for example, to persist the full set of messages returned by one of the
[online fetchers](@ref Fetching-from-Services).

!!! note

    OMM messages are always written with version `3.0`, regardless of the version stored in
    the parsed message. `NanoDate` values are written with nine fractional digits,
    preserving nanosecond precision. Optional sections (spacecraft parameters, TLE-related
    parameters, the covariance matrix, and user-defined parameters) are only written when
    the corresponding fields are present in the message.
