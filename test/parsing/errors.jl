## Description #############################################################################
#
# Parsing error path tests.
#
############################################################################################

@testset "Errors" verbose = true begin
    # == Missing id Attribute ==============================================================

    @testset "Missing id Attribute" begin
        xml = replace(_minimal_omm_xml(), "id=\"CCSDS_OMM_VERS\" " => "")
        @test_throws OdmParseError parse_omm(xml)
    end

    # == Missing Required Header Fields ====================================================

    @testset "Missing Required Header Fields" begin
        @test_throws OdmParseError parse_omm(_minimal_omm_xml(; creation_date = ""))
        @test_throws OdmParseError parse_omm(_minimal_omm_xml(; originator = ""))
    end

    # == Unsupported Version ===============================================================

    @testset "Unsupported Version" begin
        xml = _minimal_omm_xml(omm_version = "1.0")
        @test_throws OdmParseError parse_omm(xml)
    end

    # == Version 2.0 Rules =================================================================

    @testset "Version 2.0 Rules" begin
        v2_tle_params = """
        <tleParameters>
          <BSTAR>1e-4</BSTAR>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>
        </tleParameters>
        """

        # A valid version 2.0 message must parse.
        omm = parse_omm(
            _minimal_omm_xml(; omm_version = "2.0", tle_params_xml = v2_tle_params)
        )
        @test omm isa OrbitMeanElementsMessage
        @test omm.version == v"2.0"

        # `CLASSIFICATION` and `MESSAGE_ID` were introduced in version 3.0.
        @test_throws OdmParseError parse_omm(
            _minimal_omm_xml(; omm_version = "2.0", classification = "UNCLASSIFIED")
        )
        @test_throws OdmParseError parse_omm(
            _minimal_omm_xml(; omm_version = "2.0", message_id = "MESSAGE-1")
        )

        # `BTERM` and `AGOM` were introduced in version 3.0, whereas `BSTAR` and
        # `MEAN_MOTION_DDOT` are required in version 2.0.
        bterm_params = """
        <tleParameters>
          <BTERM>1e-4</BTERM>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>
        </tleParameters>
        """
        agom_params = """
        <tleParameters>
          <BSTAR>1e-4</BSTAR>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <AGOM>1e-4</AGOM>
        </tleParameters>
        """
        missing_bstar_params = """
        <tleParameters>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>
        </tleParameters>
        """
        missing_ddot_params = """
        <tleParameters>
          <BSTAR>1e-4</BSTAR>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
        </tleParameters>
        """

        for tle_params_xml in
            (bterm_params, agom_params, missing_bstar_params, missing_ddot_params)
            @test_throws OdmParseError parse_omm(
                _minimal_omm_xml(; omm_version = "2.0", tle_params_xml)
            )
        end
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
        @test_throws OdmParseError parse_omm(xml)
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
        @test_throws OdmParseError parse_omm(xml)
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
        @test_throws OdmParseError parse_omm(xml)
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
        @test_throws OdmParseError parse_omm(xml)
    end

    # == Missing OBJECT_NAME ===============================================================

    @testset "Missing OBJECT_NAME" begin
        xml = _minimal_omm_xml(object_name = "")
        @test_throws OdmParseError parse_omm(xml)
    end

    # == Missing EPOCH =====================================================================

    @testset "Missing EPOCH" begin
        xml = _minimal_omm_xml(epoch = "")
        @test_throws OdmParseError parse_omm(xml)
    end

    # == Missing Both SEMI_MAJOR_AXIS and MEAN_MOTION ======================================

    @testset "Missing SEMI_MAJOR_AXIS and MEAN_MOTION" begin
        xml = _minimal_omm_xml(semi_major_axis = "", mean_motion = "")
        @test_throws OdmParseError parse_omm(xml)
    end

    @testset "Both SEMI_MAJOR_AXIS and MEAN_MOTION" begin
        xml = _minimal_omm_xml(semi_major_axis = "7134.084")
        @test_throws OdmParseError parse_omm(xml)
    end

    @testset "Incomplete TLE Parameters" begin
        bstar_only = "<tleParameters><BSTAR>1e-4</BSTAR></tleParameters>"
        missing_drag = """
        <tleParameters>
          <MEAN_MOTION_DOT>0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0</MEAN_MOTION_DDOT>
        </tleParameters>
        """

        @test_throws OdmParseError parse_omm(_minimal_omm_xml(tle_params_xml = bstar_only))
        @test_throws OdmParseError parse_omm(
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
        @test_throws OdmParseError parse_omm(_minimal_omm_xml(tle_params_xml = both_drag))
        @test_throws OdmParseError parse_omm(
            _minimal_omm_xml(tle_params_xml = both_second_derivatives)
        )
    end

    # == Comments-Only TLE Parameters ======================================================

    @testset "Comments-Only TLE Parameters" begin
        # A comments-only section is present, so its mandatory-field rules apply. This
        # matches the `OrbitMeanElementsMessage` constructor, which would otherwise reject
        # copying the parsed message.
        tle_xml = "<tleParameters><COMMENT>TLE section</COMMENT></tleParameters>"
        @test_throws OdmParseError parse_omm(_minimal_omm_xml(; tle_params_xml = tle_xml))
    end

    # == Empty CLASSIFICATION_TYPE =========================================================

    @testset "Empty CLASSIFICATION_TYPE" begin
        tle_xml = """
        <tleParameters><CLASSIFICATION_TYPE></CLASSIFICATION_TYPE></tleParameters>
        """
        xml = _minimal_omm_xml(tle_params_xml = tle_xml)
        @test_throws OdmParseError parse_omm(xml)
    end

    # == Empty KVN String Values ===========================================================

    kvn = """
    CCSDS_OMM_VERS = 3.0
    CREATION_DATE = 2025-12-30T23:36:37
    ORIGINATOR = 18 SPCS
    OBJECT_NAME = AMAZONIA 1
    OBJECT_ID = 2021-015A
    CENTER_NAME = EARTH
    REF_FRAME = TEME
    TIME_SYSTEM = UTC
    MEAN_ELEMENT_THEORY = SGP4
    EPOCH = 2025-12-30T18:12:04.533984
    MEAN_MOTION = 14.40772474
    ECCENTRICITY = 0.00011240
    INCLINATION = 98.3721
    RA_OF_ASC_NODE = 75.0877
    ARG_OF_PERICENTER = 97.3772
    MEAN_ANOMALY = 262.7545
    """

    @testset "Empty KVN String Values" begin
        # An empty value for a mandatory string field must be treated as absent.
        @test_throws OdmParseError parse_omm(
            replace(kvn, "ORIGINATOR = 18 SPCS" => "ORIGINATOR ="); file_type = :kvn
        )
        @test_throws OdmParseError parse_omm(
            replace(kvn, "OBJECT_NAME = AMAZONIA 1" => "OBJECT_NAME ="); file_type = :kvn
        )

        # A blank `ORIGINATOR` is allowed in OMM version 2.0.
        kvn_v2 = replace(
            kvn,
            "CCSDS_OMM_VERS = 3.0" => "CCSDS_OMM_VERS = 2.0",
            "ORIGINATOR = 18 SPCS" => "ORIGINATOR =",
        )
        omm = parse_omm(kvn_v2; file_type = :kvn)
        @test omm.header.originator == ""
    end

    # == Missing CREATION_DATE in KVN ======================================================

    @testset "Missing CREATION_DATE in KVN" begin
        kvn_no_date = replace(kvn, "CREATION_DATE = 2025-12-30T23:36:37\n" => "")

        # The presence requirement applies to every format when parsing strictly.
        @test_throws OdmParseError parse_omm(kvn_no_date; file_type = :kvn)

        omm = parse_omm(kvn_no_date; file_type = :kvn, strict = false)
        @test omm.header.creation_date === nothing
    end

    # == Duplicate KVN Keywords ============================================================

    @testset "Duplicate KVN Keywords" begin
        kvn_dup = kvn * "INCLINATION = 0.0\n"

        exception = try
            parse_omm(kvn_dup; file_type = :kvn)
            nothing
        catch exception
            exception
        end

        @test exception isa OdmParseError
        @test occursin("Duplicate OMM keyword `INCLINATION`", exception.msg)
        @test exception.keyword == "INCLINATION"
        @test exception.line == 17
        @test sprint(showerror, exception) ==
            "OdmParseError: Duplicate OMM keyword `INCLINATION` in line 17. (line 17)"
    end

    # == Unknown Root Tag ==================================================================

    @testset "Unknown Root Tag" begin
        xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <foo><bar/></foo>
        """
        @test_throws OdmParseError parse_odm(xml)
        @test_throws OdmParseError parse_omms(xml)
        @test isnothing(parse_omm(xml))
    end

    # == Unknown Optional-Section Elements =================================================

    @testset "Unknown Optional-Section Elements" begin
        covariance_xml = "<covarianceMatrix><UNKNOWN>1.0</UNKNOWN></covarianceMatrix>"
        user_defined_xml = """
        <userDefinedParameters><UNKNOWN>value</UNKNOWN></userDefinedParameters>
        """

        @test_throws OdmParseError parse_omm(
            _minimal_omm_xml(; covariance_matrix_xml = covariance_xml)
        )
        @test_throws OdmParseError parse_omm(
            _minimal_omm_xml(; user_defined_xml = user_defined_xml)
        )
    end
end

@testset "Invalid Numeric Values" begin
    # The error message must name the OMM field that contains the invalid value.
    exception = try
        parse_omm(_minimal_omm_xml(; mean_motion = "abc"))
        nothing
    catch exception
        exception
    end

    @test exception isa OdmParseError
    @test occursin("MEAN_MOTION", exception.msg)
    @test exception.keyword == "MEAN_MOTION"
    @test isnothing(exception.line)
    @test sprint(showerror, exception) == "OdmParseError: " * exception.msg

    exception = try
        parse_omm(_minimal_omm_xml(; tle_params_xml = """
                                     <tleParameters>
                                         <NORAD_CAT_ID>not-a-number</NORAD_CAT_ID>
                                         <BSTAR>0.0001</BSTAR>
                                         <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
                                         <MEAN_MOTION_DDOT>0.0</MEAN_MOTION_DDOT>
                                     </tleParameters>
                                     """))
        nothing
    catch exception
        exception
    end

    @test exception isa OdmParseError
    @test occursin("NORAD_CAT_ID", exception.msg)
end

@testset "Invalid Date Values" begin
    # The error message must name the OMM field that contains the invalid date.
    for epoch in ("not-a-date", "2025-366T00:00:00")
        exception = try
            parse_omm(_minimal_omm_xml(; epoch))
            nothing
        catch exception
            exception
        end

        @test exception isa OdmParseError
        @test occursin("EPOCH", exception.msg)
    end
end
