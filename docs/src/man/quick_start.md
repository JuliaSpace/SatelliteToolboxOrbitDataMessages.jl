# Quick Start

```@meta
CurrentModule = SatelliteToolboxOrbitDataMessages
```

```@setup quick_start
using SatelliteToolboxOrbitDataMessages

omm_xml = """
<?xml version="1.0" encoding="utf-8"?>
<ndm xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><omm id="CCSDS_OMM_VERS" version="3.0"><header><COMMENT>GENERATED VIA SPACE-TRACK.ORG API</COMMENT><CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE><ORIGINATOR>18 SPCS</ORIGINATOR></header><body><segment><metadata><OBJECT_NAME>AMAZONIA 1</OBJECT_NAME><OBJECT_ID>2021-015A</OBJECT_ID><CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME><TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY></metadata><data><meanElements><EPOCH>2025-12-30T18:12:04.533984</EPOCH><MEAN_MOTION>14.40772474</MEAN_MOTION><ECCENTRICITY>0.00011240</ECCENTRICITY><INCLINATION>98.3721</INCLINATION><RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE><ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER><MEAN_ANOMALY>262.7545</MEAN_ANOMALY></meanElements><tleParameters><EPHEMERIS_TYPE>0</EPHEMERIS_TYPE><CLASSIFICATION_TYPE>U</CLASSIFICATION_TYPE><NORAD_CAT_ID>47699</NORAD_CAT_ID><ELEMENT_SET_NO>999</ELEMENT_SET_NO><REV_AT_EPOCH>25439</REV_AT_EPOCH><BSTAR>0.00015330000000</BSTAR><MEAN_MOTION_DOT>0.00000447</MEAN_MOTION_DOT><MEAN_MOTION_DDOT>0.0000000000000</MEAN_MOTION_DDOT></tleParameters></data></segment></body></omm></ndm>
"""
```

Let's suppose we obtained the Orbit Mean-Elements Message (OMM) below describing the orbit of
the [Amazonia 1](https://en.wikipedia.org/wiki/Amazonia-1) satellite. This is the XML format
returned by services such as [Space-Track](https://www.space-track.org):

```xml
<?xml version="1.0" encoding="utf-8"?>
<ndm><omm id="CCSDS_OMM_VERS" version="3.0">
  <header>
    <COMMENT>GENERATED VIA SPACE-TRACK.ORG API</COMMENT>
    <CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE>
    <ORIGINATOR>18 SPCS</ORIGINATOR>
  </header>
  <body><segment>
    <metadata>
      <OBJECT_NAME>AMAZONIA 1</OBJECT_NAME>
      <OBJECT_ID>2021-015A</OBJECT_ID>
      <CENTER_NAME>EARTH</CENTER_NAME>
      <REF_FRAME>TEME</REF_FRAME>
      <TIME_SYSTEM>UTC</TIME_SYSTEM>
      <MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY>
    </metadata>
    <data>
      <meanElements>
        <EPOCH>2025-12-30T18:12:04.533984</EPOCH>
        <MEAN_MOTION>14.40772474</MEAN_MOTION>
        <ECCENTRICITY>0.00011240</ECCENTRICITY>
        <INCLINATION>98.3721</INCLINATION>
        <RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE>
        <ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER>
        <MEAN_ANOMALY>262.7545</MEAN_ANOMALY>
      </meanElements>
    </data>
  </segment></body>
</omm></ndm>
```

Assuming the string above is stored in the variable `omm_xml`, we can parse it into an
[`OrbitMeanElementsMessage`](@ref) object using [`parse_omm`](@ref):

```@repl quick_start
omm = parse_omm(omm_xml)
```

The message fields are organized following the CCSDS standard hierarchy (header, metadata,
and data). We can access them directly:

```@repl quick_start
omm.header.originator

omm.body.segment.metadata.object_name

omm.body.segment.data.epoch

omm.body.segment.data.inclination
```

If the OMM is stored in a file, use [`read_omm`](@ref) instead:

```julia
omm = read_omm("amazonia_1.xml")
```

From here, you can explore the rest of the manual to learn how to
[create OMMs from scratch](@ref Creating-OMMs), [write them to files](@ref
Reading-and-Writing-Files), [fetch them online](@ref Fetching-from-Services), or
[convert them to a TLE](@ref Converting-to-TLE).
