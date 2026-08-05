## Description #############################################################################
#
# KVN writing tests.
#
############################################################################################

@testset "KVN Writing" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == Output Structure ==================================================================

    @testset "Output Structure" begin
        buf = IOBuffer()
        write_omm(buf, omm; file_type = :kvn)
        out = String(take!(buf))

        @test startswith(out, "CCSDS_OMM_VERS")
        @test occursin("COMMENT GENERATED VIA SPACE-TRACK.ORG API", out)
        @test occursin(r"MEAN_MOTION +?= 14\.40772474 +\[rev/day\]", out)
        @test occursin(r"OBJECT_NAME +?= AMAZONIA 1", out)
        @test occursin("USER_DEFINED_SEMIMAJOR_AXIS", out)
    end

    # == Round Trip ========================================================================

    @testset "Round Trip" begin
        buf = IOBuffer()
        write_omm(buf, omm; file_type = :kvn)
        omm_reparsed = parse_omm(String(take!(buf)); file_type = :kvn)

        @test omm_reparsed == omm
    end

    @testset "Round Trip With Covariance Matrix" begin
        omm_cov = parse_omm(_minimal_omm_xml(; covariance_matrix_xml = _COV_XML))

        buf = IOBuffer()
        write_omm(buf, omm_cov; file_type = :kvn)
        out = String(take!(buf))

        # The covariance elements carry their CCSDS units in the KVN output.
        @test occursin(r"CX_X +?= 1\.0 +\[km\*\*2\]", out)
        @test occursin(r"CX_DOT_X +?= 7\.0 +\[km\*\*2/s\]", out)
        @test occursin(r"CX_DOT_X_DOT +?= 10\.0 +\[km\*\*2/s\*\*2\]", out)

        omm_reparsed = parse_omm(out; file_type = :kvn)

        @test omm_reparsed == omm_cov
        @test omm_reparsed.data.covariance_matrix.comments ==
            ["This is a covariance matrix"]
        @test omm_reparsed.data.covariance_matrix.cz_dot_z_dot == 21.0
    end

    # == Comments-Only Optional Section ====================================================

    @testset "Comments-Only Optional Section" begin
        # The flat KVN format cannot represent the comments of a section without fields,
        # so they are dropped with a warning instead of being silently attributed to the
        # next section on reparse.
        omm_sc = OrbitMeanElementsMessage(omm; spacecraft_parameters_comments = ["SC"])

        buf = IOBuffer()
        @test_logs (:warn, r"spacecraft parameters") write_omm(
            buf, omm_sc; file_type = :kvn
        )
        out = String(take!(buf))

        @test !occursin("COMMENT SC", out)
        @test parse_omm(out; file_type = :kvn) ==
            OrbitMeanElementsMessage(omm_sc; spacecraft_parameters_comments = String[])
    end

    # == Vector Form =======================================================================

    @testset "Vector Form" begin
        buf = IOBuffer()
        write_omm(buf, [omm, omm]; file_type = :kvn)
        omms = parse_omms(String(take!(buf)); file_type = :kvn)

        @test length(omms) == 2
        @test omms[1] == omm
        @test omms[2] == omm
    end

    # == File Type Inference From the Extension ============================================

    @testset "File Extension Inference" begin
        outfile = joinpath(mktempdir(), "omm.kvn")
        write_omm(outfile, omm)

        out = read(outfile, String)
        @test startswith(out, "CCSDS_OMM_VERS")
        @test read_omm(outfile) == omm

        outfile = joinpath(mktempdir(), "omm.xml")
        write_omm(outfile, omm)

        out = read(outfile, String)
        @test startswith(out, "<?xml")
        @test read_omm(outfile) == omm
    end

    # == Errors ============================================================================

    @testset "Unsupported File Type" begin
        @test_throws ArgumentError write_omm(IOBuffer(), omm; file_type = :json)
        @test_throws ArgumentError write_omm(IOBuffer(), [omm]; file_type = :json)
    end
end
