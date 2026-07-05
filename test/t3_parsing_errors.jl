## Description #############################################################################
#
# T3 — Parsing error path tests.
#
############################################################################################

@testset "T3: Parsing errors" verbose = true begin
    # == T3.1: Missing id attribute =====================================================

    @testset "T3.1: Missing id attribute" begin
        xml = replace(_minimal_omm_xml(), "id=\"CCSDS_OMM_VERS\" " => "")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.2: Unsupported version ======================================================

    @testset "T3.2: Unsupported version" begin
        xml = _minimal_omm_xml(omm_version="1.0")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.3: Missing header ===========================================================

    @testset "T3.3: Missing header" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <omm id="CCSDS_OMM_VERS" version="3.0">
          <body><segment><metadata>
            <OBJECT_NAME>AMAZONIA 1</OBJECT_NAME>
            <OBJECT_ID>2021-015A</OBJECT_ID>
            <CENTER_NAME>EARTH</CENTER_NAME>
            <REF_FRAME>TEME</REF_FRAME>
            <TIME_SYSTEM>UTC</TIME_SYSTEM>
            <MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY>
          </metadata><data><meanElements>
            <EPOCH>2025-12-30T18:12:04.533984</EPOCH>
            <MEAN_MOTION>14.40772474</MEAN_MOTION>
            <ECCENTRICITY>0.00011240</ECCENTRICITY>
            <INCLINATION>98.3721</INCLINATION>
            <RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE>
            <ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER>
            <MEAN_ANOMALY>262.7545</MEAN_ANOMALY>
          </meanElements></data></segment></body>
        </omm>
        """
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.4: Missing body =============================================================

    @testset "T3.4: Missing body" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <omm id="CCSDS_OMM_VERS" version="3.0">
          <header>
            <CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE>
            <ORIGINATOR>18 SPCS</ORIGINATOR>
          </header>
        </omm>
        """
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.5: Missing segment ==========================================================

    @testset "T3.5: Missing segment" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <omm id="CCSDS_OMM_VERS" version="3.0">
          <header>
            <CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE>
            <ORIGINATOR>18 SPCS</ORIGINATOR>
          </header>
          <body></body>
        </omm>
        """
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.6: Multiple segments ========================================================

    @testset "T3.6: Multiple segments" begin
        seg = "<segment><metadata>
            <OBJECT_NAME>AMAZONIA 1</OBJECT_NAME>
            <OBJECT_ID>2021-015A</OBJECT_ID>
            <CENTER_NAME>EARTH</CENTER_NAME>
            <REF_FRAME>TEME</REF_FRAME>
            <TIME_SYSTEM>UTC</TIME_SYSTEM>
            <MEAN_ELEMENT_THEORY>SGP4</MEAN_ELEMENT_THEORY>
          </metadata><data><meanElements>
            <EPOCH>2025-12-30T18:12:04.533984</EPOCH>
            <MEAN_MOTION>14.40772474</MEAN_MOTION>
            <ECCENTRICITY>0.00011240</ECCENTRICITY>
            <INCLINATION>98.3721</INCLINATION>
            <RA_OF_ASC_NODE>75.0877</RA_OF_ASC_NODE>
            <ARG_OF_PERICENTER>97.3772</ARG_OF_PERICENTER>
            <MEAN_ANOMALY>262.7545</MEAN_ANOMALY>
          </meanElements></data></segment>"

        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <omm id="CCSDS_OMM_VERS" version="3.0">
          <header>
            <CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE>
            <ORIGINATOR>18 SPCS</ORIGINATOR>
          </header>
          <body>$(seg)$(seg)</body>
        </omm>
        """
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.7: Missing OBJECT_NAME ======================================================

    @testset "T3.7: Missing OBJECT_NAME" begin
        xml = _minimal_omm_xml(object_name="")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.8: Missing EPOCH ============================================================

    @testset "T3.8: Missing EPOCH" begin
        xml = _minimal_omm_xml(epoch="")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.9: Missing both SEMI_MAJOR_AXIS and MEAN_MOTION =============================

    @testset "T3.9: Missing SEMI_MAJOR_AXIS and MEAN_MOTION" begin
        xml = _minimal_omm_xml(semi_major_axis="", mean_motion="")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == T3.10: Empty CLASSIFICATION_TYPE ===============================================

    @testset "T3.10: Empty CLASSIFICATION_TYPE" begin
        tle_xml = "<tleParameters><CLASSIFICATION_TYPE></CLASSIFICATION_TYPE></tleParameters>"
        xml = _minimal_omm_xml(tle_params_xml=tle_xml)
        omm = parse_omm(xml)
        @test !isnothing(omm)
        @test isnothing(omm.body.segment.data.classification_type)
    end

    # == T3.11: Unknown root tag ========================================================

    @testset "T3.11: Unknown root tag" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <foo><bar/></foo>
        """
        @test_throws ArgumentError parse_odm(xml)
    end
end
