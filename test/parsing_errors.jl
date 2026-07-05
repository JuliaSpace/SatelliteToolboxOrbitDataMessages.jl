## Description #############################################################################
#
# Parsing error path tests.
#
############################################################################################

@testset "Errors" verbose = true begin
    # == Missing id attribute ==============================================================

    @testset "Missing id attribute" begin
        xml = replace(_minimal_omm_xml(), "id=\"CCSDS_OMM_VERS\" " => "")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Unsupported version ===============================================================

    @testset "Unsupported version" begin
        xml = _minimal_omm_xml(omm_version="1.0")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Missing header ====================================================================

    @testset "Missing header" begin
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

    # == Missing body ======================================================================

    @testset "Missing body" begin
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

    # == Missing segment ===================================================================

    @testset "Missing segment" begin
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

    # == Multiple segments =================================================================

    @testset "Multiple segments" begin
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

    # == Missing OBJECT_NAME ===============================================================

    @testset "Missing OBJECT_NAME" begin
        xml = _minimal_omm_xml(object_name="")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Missing EPOCH =====================================================================

    @testset "Missing EPOCH" begin
        xml = _minimal_omm_xml(epoch="")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Missing both SEMI_MAJOR_AXIS and MEAN_MOTION ======================================

    @testset "Missing SEMI_MAJOR_AXIS and MEAN_MOTION" begin
        xml = _minimal_omm_xml(semi_major_axis="", mean_motion="")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Empty CLASSIFICATION_TYPE =========================================================

    @testset "Empty CLASSIFICATION_TYPE" begin
        tle_xml = "<tleParameters><CLASSIFICATION_TYPE></CLASSIFICATION_TYPE></tleParameters>"
        xml = _minimal_omm_xml(tle_params_xml=tle_xml)
        omm = parse_omm(xml)
        @test !isnothing(omm)
        @test isnothing(omm.body.segment.data.classification_type)
    end

    # == Unknown root tag ==================================================================

    @testset "Unknown root tag" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <foo><bar/></foo>
        """
        @test_throws ArgumentError parse_odm(xml)
    end
end
