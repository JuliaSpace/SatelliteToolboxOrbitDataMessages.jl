## Description #############################################################################
#
# Optional fields tests.
#
############################################################################################

@testset "Optional fields" verbose = true begin
    # == Minimal OMM (required fields only) ================================================

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

    # == semi_major_axis without mean_motion ===============================================

    @testset "semi_major_axis without mean_motion" begin
        xml = _minimal_omm_xml(semi_major_axis="7134.084", mean_motion="")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.data.semi_major_axis ≈ 7134.084
        @test isnothing(omm.body.segment.data.mean_motion)
    end

    # == mean_motion without semi_major_axis ===============================================

    @testset "mean_motion without semi_major_axis" begin
        xml = _minimal_omm_xml(mean_motion="14.40772474")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.data.mean_motion ≈ 14.40772474
        @test isnothing(omm.body.segment.data.semi_major_axis)
    end

    # == ref_frame_epoch set ===============================================================

    @testset "ref_frame_epoch set" begin
        xml = _minimal_omm_xml(ref_frame_epoch="2000-01-01T12:00:00")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.metadata.ref_frame_epoch == NanoDate("2000-01-01T12:00:00")
    end
end
