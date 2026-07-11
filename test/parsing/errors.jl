## Description #############################################################################
#
# Parsing error path tests.
#
############################################################################################

@testset "Errors" verbose = true begin
    # == Missing id Attribute ==============================================================

    @testset "Missing id Attribute" begin
        xml = replace(_minimal_omm_xml(), "id=\"CCSDS_OMM_VERS\" " => "")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Missing Required Header Fields ====================================================

    @testset "Missing Required Header Fields" begin
        @test_throws ArgumentError parse_omm(_minimal_omm_xml(; creation_date = ""))
        @test_throws ArgumentError parse_omm(_minimal_omm_xml(; originator = ""))
    end

    # == Unsupported Version ===============================================================

    @testset "Unsupported Version" begin
        xml = _minimal_omm_xml(omm_version="1.0")
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Missing Header ====================================================================

    @testset "Missing Header" begin
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

    # == Missing Body ======================================================================

    @testset "Missing Body" begin
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

    # == Missing Segment ===================================================================

    @testset "Missing Segment" begin
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

    # == Multiple Segments =================================================================

    @testset "Multiple Segments" begin
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

    # == Missing Both SEMI_MAJOR_AXIS and MEAN_MOTION ======================================

    @testset "Missing SEMI_MAJOR_AXIS and MEAN_MOTION" begin
        xml = _minimal_omm_xml(semi_major_axis="", mean_motion="")
        @test_throws ArgumentError parse_omm(xml)
    end

    @testset "Both SEMI_MAJOR_AXIS and MEAN_MOTION" begin
        xml = _minimal_omm_xml(semi_major_axis = "7134.084")
        @test_throws ArgumentError parse_omm(xml)
    end

    @testset "Incomplete TLE Parameters" begin
        bstar_only = "<tleParameters><BSTAR>1e-4</BSTAR></tleParameters>"
        missing_drag = """
        <tleParameters>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>
        </tleParameters>
        """

        @test_throws ArgumentError parse_omm(_minimal_omm_xml(tle_params_xml = bstar_only))
        @test_throws ArgumentError parse_omm(
            _minimal_omm_xml(tle_params_xml = missing_drag)
        )

        both_drag = """
        <tleParameters>
          <BSTAR>1e-4</BSTAR><BTERM>1e-4</BTERM>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT><MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>
        </tleParameters>
        """
        both_second_derivatives = """
        <tleParameters>
          <BSTAR>1e-4</BSTAR><MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT><AGOM>1e-4</AGOM>
        </tleParameters>
        """
        @test_throws ArgumentError parse_omm(
            _minimal_omm_xml(tle_params_xml = both_drag)
        )
        @test_throws ArgumentError parse_omm(
            _minimal_omm_xml(tle_params_xml = both_second_derivatives)
        )
    end

    # == Empty CLASSIFICATION_TYPE =========================================================

    @testset "Empty CLASSIFICATION_TYPE" begin
        tle_xml = """
        <tleParameters><CLASSIFICATION_TYPE></CLASSIFICATION_TYPE></tleParameters>
        """
        xml = _minimal_omm_xml(tle_params_xml=tle_xml)
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Unknown Root Tag ==================================================================

    @testset "Unknown Root Tag" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <foo><bar/></foo>
        """
        @test_throws ArgumentError parse_odm(xml)
        @test_throws ArgumentError parse_omms(xml)
        @test isnothing(parse_omm(xml))
    end

    # == Unknown Optional-Section Elements =================================================

    @testset "Unknown Optional-Section Elements" begin
        covariance_xml = "<covarianceMatrix><UNKNOWN>1.0</UNKNOWN></covarianceMatrix>"
        user_defined_xml = """
        <userDefinedParameters><UNKNOWN>value</UNKNOWN></userDefinedParameters>
        """

        @test_throws ArgumentError parse_omm(
            _minimal_omm_xml(; covariance_matrix_xml = covariance_xml)
        )
        @test_throws ArgumentError parse_omm(
            _minimal_omm_xml(; user_defined_xml = user_defined_xml)
        )
    end
end
