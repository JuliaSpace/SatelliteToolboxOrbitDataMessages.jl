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
        @test omm.header.classification    === nothing
        @test omm.header.message_id        === nothing
        @test isempty(omm.body.segment.metadata.comments)
        @test omm.body.segment.metadata.ref_frame_epoch === nothing
        @test isempty(omm.body.segment.data.comments)
        @test isempty(omm.body.segment.data.mean_elements_comments)
        @test omm.body.segment.data.semi_major_axis      === nothing
        @test omm.body.segment.data.GM                   === nothing
        @test isempty(omm.body.segment.data.spacecraft_parameters_comments)
        @test omm.body.segment.data.mass                    === nothing
        @test isempty(omm.body.segment.data.tle_parameters_comments)
        @test omm.body.segment.data.ephemeris_type          === nothing
        @test omm.body.segment.data.classification_type     === nothing
        @test omm.body.segment.data.norad_cat_id            === nothing
        @test omm.body.segment.data.bstar                   === nothing
        @test omm.body.segment.data.user_defined_parameters === nothing
    end

    # == semi_major_axis Without mean_motion ===============================================

    @testset "semi_major_axis Without mean_motion" begin
        xml = _minimal_omm_xml(semi_major_axis="7134.084", mean_motion="")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.data.semi_major_axis ≈ 7134.084
        @test isnothing(omm.body.segment.data.mean_motion)
    end

    # == mean_motion Without semi_major_axis ===============================================

    @testset "mean_motion Without semi_major_axis" begin
        xml = _minimal_omm_xml(mean_motion="14.40772474")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.data.mean_motion ≈ 14.40772474
        @test isnothing(omm.body.segment.data.semi_major_axis)
    end

    # == ref_frame_epoch Set ===============================================================

    @testset "ref_frame_epoch Set" begin
        xml = _minimal_omm_xml(ref_frame_epoch="2000-01-01T12:00:00")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.metadata.ref_frame_epoch == NanoDate("2000-01-01T12:00:00")
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
        xml = _minimal_omm_xml(
            ;
            classification = "UNCLASSIFIED",
            message_id = "OMM-1",
            metadata_comment = "metadata",
            gm = "398600.4418",
            spacecraft_params_xml = spacecraft_xml,
            tle_params_xml = tle_xml
        )
        omm = parse_omm(xml)
        data = omm.body.segment.data

        @test omm.header.classification == "UNCLASSIFIED"
        @test omm.header.message_id == "OMM-1"
        @test omm.body.segment.metadata.comments == ["metadata"]
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
