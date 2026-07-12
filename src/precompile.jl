@setup_workload begin
    omm_xml = """
    <omm id="CCSDS_OMM_VERS" version="3.0">
      <header>
        <CREATION_DATE>2025-01-01T00:00:00</CREATION_DATE>
        <ORIGINATOR>SatelliteToolbox</ORIGINATOR>
      </header>
      <body><segment>
        <metadata>
          <OBJECT_NAME>SAMPLE</OBJECT_NAME><OBJECT_ID>2025-001A</OBJECT_ID>
          <CENTER_NAME>EARTH</CENTER_NAME><REF_FRAME>TEME</REF_FRAME>
          <TIME_SYSTEM>UTC</TIME_SYSTEM><MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY>
        </metadata>
        <data>
          <meanElements>
            <EPOCH>2025-01-01T00:00:00</EPOCH><MEAN_MOTION>15.0</MEAN_MOTION>
            <ECCENTRICITY>0.001</ECCENTRICITY><INCLINATION>51.6</INCLINATION>
            <RA_OF_ASC_NODE>20.0</RA_OF_ASC_NODE>
            <ARG_OF_PERICENTER>30.0</ARG_OF_PERICENTER>
            <MEAN_ANOMALY>40.0</MEAN_ANOMALY>
          </meanElements>
          <tleParameters>
            <EPHEMERIS_TYPE>0</EPHEMERIS_TYPE><CLASSIFICATION_TYPE>U</CLASSIFICATION_TYPE>
            <NORAD_CAT_ID>99999</NORAD_CAT_ID><ELEMENT_SET_NO>1</ELEMENT_SET_NO>
            <REV_AT_EPOCH>1</REV_AT_EPOCH><BSTAR>0.0001</BSTAR>
            <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
            <MEAN_MOTION_DDOT>0.0</MEAN_MOTION_DDOT>
          </tleParameters>
        </data>
      </segment></body>
    </omm>
    """

    @compile_workload begin
        omm = parse_omm(omm_xml)
        write_omm(IOBuffer(), omm)
        show(IOBuffer(), MIME("text/plain"), omm)
    end
end
