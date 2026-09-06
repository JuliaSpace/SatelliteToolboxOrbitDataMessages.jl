## Description #############################################################################
#
# Optional fields tests.
#
############################################################################################

@testset "Optional Fields" verbose = true begin
    # == Minimal OMM (Required Fields Only) ================================================

    @testset "Minimal OMM" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test isempty(omm.header.comments)
        @test omm.header.classification === nothing
        @test omm.header.message_id === nothing
        @test isempty(omm.metadata.comments)
        @test omm.metadata.ref_frame_epoch === nothing
        @test isempty(omm.data.comments)
        @test isempty(omm.data.mean_elements_comments)
        @test omm.data.semi_major_axis === nothing
        @test omm.data.GM === nothing
        @test isempty(omm.data.spacecraft_parameters_comments)
        @test omm.data.mass === nothing
        @test isempty(omm.data.tle_parameters_comments)
        @test omm.data.ephemeris_type === nothing
        @test omm.data.classification_type === nothing
        @test omm.data.norad_cat_id === nothing
        @test omm.data.bstar === nothing
        @test isempty(omm.data.user_defined_parameters)
    end

    # == semi_major_axis Without mean_motion ===============================================

    @testset "semi_major_axis Without mean_motion" begin
        xml = _minimal_omm_xml(semi_major_axis = "7134.084", mean_motion = "")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.data.semi_major_axis ≈ 7134.084
        @test isnothing(omm.data.mean_motion)
    end

    # == mean_motion Without semi_major_axis ===============================================

    @testset "mean_motion Without semi_major_axis" begin
        xml = _minimal_omm_xml(mean_motion = "14.40772474")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.data.mean_motion ≈ 14.40772474
        @test isnothing(omm.data.semi_major_axis)
    end

    # == ref_frame_epoch Set ===============================================================

    @testset "ref_frame_epoch Set" begin
        xml = _minimal_omm_xml(ref_frame_epoch = "2000-01-01T12:00:00")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.metadata.ref_frame_epoch == NanoDate("2000-01-01T12:00:00")
    end

    # == Blank ORIGINATOR in OMM 2.0 =======================================================

    @testset "Blank ORIGINATOR in OMM 2.0" begin
        # The `ORIGINATOR` may be absent in OMM version 2.0, accommodating real-world files
        # (e.g. from Celestrak) that omit its value. In this case, it defaults to an empty
        # string.
        xml = _minimal_omm_xml(; omm_version = "2.0", originator = "")

        omm = parse_omm(xml)
        @test omm.header.originator == ""

        kvn = """
        CCSDS_OMM_VERS      = 2.0
        CREATION_DATE       = 2025-12-30T23:36:37
        OBJECT_NAME         = AMAZONIA 1
        OBJECT_ID           = 2021-015A
        CENTER_NAME         = EARTH
        REF_FRAME           = TEME
        TIME_SYSTEM         = UTC
        MEAN_ELEMENT_THEORY = SGP4
        EPOCH               = 2025-12-30T18:12:04.533984
        MEAN_MOTION         = 14.40772474
        ECCENTRICITY        = 0.0001124
        INCLINATION         = 98.3721
        RA_OF_ASC_NODE      = 75.0877
        ARG_OF_PERICENTER   = 97.3772
        MEAN_ANOMALY        = 262.7545
        """

        omm = parse_omm(kvn; format = :kvn)
        @test omm.header.originator == ""

        # Such an incomplete message cannot be written as OMM 3.0.
        @test_throws ArgumentError write_omm(IOBuffer(), omm)

        # The `ORIGINATOR` is still required in OMM version 3.0.
        xml = _minimal_omm_xml(; originator = "")
        @test_throws OdmParseError parse_omm(xml)
    end

    # == All Optional Scalar Fields Set ====================================================

    @testset "All Optional Scalar Fields Set" begin
        spacecraft_xml = """
        <spacecraftParameters>
          <COMMENT>spacecraft parameters</COMMENT>
          <MASS>100.0</MASS>
          <SOLAR_RAD_AREA>2.0</SOLAR_RAD_AREA>
          <SOLAR_RAD_COEFF>1.2</SOLAR_RAD_COEFF>
          <DRAG_AREA>3.0</DRAG_AREA>
          <DRAG_COEFF>2.2</DRAG_COEFF>
        </spacecraftParameters>
        """
        tle_xml = """
        <tleParameters>
          <COMMENT>TLE parameters</COMMENT>
          <BSTAR>1e-4</BSTAR>
          <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
          <MEAN_MOTION_DDOT>0.0</MEAN_MOTION_DDOT>
        </tleParameters>
        """
        xml = _minimal_omm_xml(;
            classification = "UNCLASSIFIED",
            message_id = "OMM-1",
            metadata_comment = "metadata",
            gm = "398600.4418",
            spacecraft_params_xml = spacecraft_xml,
            tle_params_xml = tle_xml,
        )
        omm = parse_omm(xml)
        data = omm.data

        @test omm.header.classification == "UNCLASSIFIED"
        @test omm.header.message_id == "OMM-1"
        @test omm.metadata.comments == ["metadata"]
        @test data.GM == 398600.4418
        @test data.spacecraft_parameters_comments == ["spacecraft parameters"]
        @test data.mass == 100.0
        @test data.solar_rad_area == 2.0
        @test data.solar_rad_coeff == 1.2
        @test data.drag_area == 3.0
        @test data.drag_coeff == 2.2
        @test data.tle_parameters_comments == ["TLE parameters"]
    end
end
