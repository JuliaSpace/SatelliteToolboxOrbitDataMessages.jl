## Description #############################################################################
#
# T5 — Optional fields tests.
#
############################################################################################

@testset "T5: Optional fields" verbose = true begin
    # == T5.1: Minimal OMM (required fields only) =======================================

    @testset "T5.1: Minimal OMM" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.comment           === nothing
        @test omm.header.classification    === nothing
        @test omm.header.message_id        === nothing
        @test omm.body.segment.metadata.comment          === nothing
        @test omm.body.segment.metadata.ref_frame_epoch === nothing
        @test omm.body.segment.data.data_comment         === nothing
        @test omm.body.segment.data.semi_major_axis      === nothing
        @test omm.body.segment.data.GM                   === nothing
        @test omm.body.segment.data.spacecraft_data_comment === nothing
        @test omm.body.segment.data.mass                    === nothing
        @test omm.body.segment.data.tle_parameters_comment  === nothing
        @test omm.body.segment.data.ephemeris_type          === nothing
        @test omm.body.segment.data.classification_type     === nothing
        @test omm.body.segment.data.norad_cat_id            === nothing
        @test omm.body.segment.data.bstar                   === nothing
        @test omm.body.segment.data.user_defined_parameters === nothing
    end

    # == T5.2: semi_major_axis without mean_motion ======================================

    @testset "T5.2: semi_major_axis without mean_motion" begin
        xml = _minimal_omm_xml(semi_major_axis="7134.084", mean_motion="")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.data.semi_major_axis ≈ 7134.084
        @test isnothing(omm.body.segment.data.mean_motion)
    end

    # == T5.3: mean_motion without semi_major_axis ======================================

    @testset "T5.3: mean_motion without semi_major_axis" begin
        xml = _minimal_omm_xml(mean_motion="14.40772474")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.data.mean_motion ≈ 14.40772474
        @test isnothing(omm.body.segment.data.semi_major_axis)
    end

    # == T5.4: ref_frame_epoch set ======================================================

    @testset "T5.4: ref_frame_epoch set" begin
        xml = _minimal_omm_xml(ref_frame_epoch="2000-01-01T12:00:00")
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.body.segment.metadata.ref_frame_epoch == NanoDate("2000-01-01T12:00:00")
    end
end
