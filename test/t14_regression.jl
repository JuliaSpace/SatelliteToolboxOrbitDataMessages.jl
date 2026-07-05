## Description #############################################################################
#
# T14 — Regression snapshot tests.
#
############################################################################################

@testset "T14: Regression snapshots" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == T14.1: Display snapshot (covered by omm_display.jl, kept for reference) =========

    @testset "T14.1: Display snapshot" begin
        result = sprint(show, MIME("text/plain"), omm)
        @test occursin("OrbitMeanElementsMessage:", result)
        @test occursin("AMAZONIA 1", result)
    end

    # == T14.2: write_omm XML snapshot ===================================================

    @testset "T14.2: write_omm XML snapshot" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))

        # The output must be parseable and round-trip the key fields.
        reparsed = parse_omm(out)
        @test !isnothing(reparsed)
        @test reparsed.body.segment.metadata.object_name == "AMAZONIA 1"
        @test reparsed.body.segment.metadata.object_id   == "2021-015A"
        @test reparsed.body.segment.data.epoch ==
            NanoDate("2025-12-30T18:12:04.533984")
        @test reparsed.body.segment.data.mean_motion ≈ 14.40772474 atol = 1e-6

        # Structural invariants.
        @test startswith(out, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        @test occursin("<omm", out)
        @test occursin("id=\"CCSDS_OMM_VERS\"", out)
        @test occursin("version=\"3.0\"", out)
        @test occursin("</omm>", out)
    end
end
