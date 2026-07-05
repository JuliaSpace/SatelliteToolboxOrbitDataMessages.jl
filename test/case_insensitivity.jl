## Description #############################################################################
#
# Tag case-insensitivity tests.
#
############################################################################################

@testset "Tag case-insensitivity" verbose = true begin
    # Build three variants of the same minimal OMM with different tag casings.
    # The parser should treat all tags case-insensitively.

    function _build_omm(tag_style::Symbol)
        if tag_style === :lower
            OMM       = "omm"
            HEADER    = "header"
            BODY      = "body"
            SEGMENT   = "segment"
            METADATA  = "metadata"
            DATA      = "data"
            MEAN_EL   = "meanelements"
        elseif tag_style === :upper
            OMM       = "OMM"
            HEADER    = "HEADER"
            BODY      = "BODY"
            SEGMENT   = "SEGMENT"
            METADATA  = "METADATA"
            DATA      = "DATA"
            MEAN_EL   = "MEANELEMENTS"
        else # :mixed
            OMM       = "Omm"
            HEADER    = "Header"
            BODY      = "Body"
            SEGMENT   = "Segment"
            METADATA  = "Metadata"
            DATA      = "Data"
            MEAN_EL   = "MeanElements"
        end

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <$OMM id="CCSDS_OMM_VERS" version="3.0">
          <$HEADER>
            <CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE>
            <ORIGINATOR>18 SPCS</ORIGINATOR>
          </$HEADER>
          <$BODY>
            <$SEGMENT>
              <$METADATA>
                <OBJECT_NAME>AMAZONIA 1</OBJECT_NAME>
                <OBJECT_ID>2021-015A</OBJECT_ID>
                <CENTER_NAME>EARTH</CENTER_NAME>
                <REF_FRAME>TEME</REF_FRAME>
                <TIME_SYSTEM>UTC</TIME_SYSTEM>
                <MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY>
              </$METADATA>
              <$DATA>
                <$MEAN_EL>
                  <EPOCH>2025-12-30T18:12:04.533984</EPOCH>
                  <MEAN_MOTION>14.40772474</MEAN_MOTION>
                  <ECCENTRICITY>0.00011240</ECCENTRICITY>
                  <INCLINATION>98.3721</INCLINATION>
                  <RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE>
                  <ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER>
                  <MEAN_ANOMALY>262.7545</MEAN_ANOMALY>
                </$MEAN_EL>
              </$DATA>
            </$SEGMENT>
          </$BODY>
        </$OMM>
        """
    end

    @testset "UPPERCASE tags" begin
        xml = _build_omm(:upper)
        omm = parse_omm(xml)
        @test !isnothing(omm)
        @test omm.header.originator == "18 SPCS"
        @test omm.body.segment.metadata.object_name == "AMAZONIA 1"
        @test omm.body.segment.data.mean_motion ≈ 14.40772474 atol = 1e-6
    end

    @testset "Mixed-case tags" begin
        xml = _build_omm(:mixed)
        omm = parse_omm(xml)
        @test !isnothing(omm)
        @test omm.header.originator == "18 SPCS"
        @test omm.body.segment.metadata.object_name == "AMAZONIA 1"
        @test omm.body.segment.data.mean_motion ≈ 14.40772474 atol = 1e-6
    end
end
