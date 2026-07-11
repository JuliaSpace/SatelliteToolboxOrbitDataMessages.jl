## Description #############################################################################
#
# Write output structure tests.
#
############################################################################################

@testset "Write structure" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == XML declaration ===================================================================

    @testset "XML declaration" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))
        @test startswith(out, "<?xml")
        @test occursin("encoding=\"UTF-8\"", out)
    end

    # == OMM root version ==================================================================

    @testset "OMM root version" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))
        @test occursin("<omm", out)
        @test occursin("version=\"3.0\"", out)
        @test occursin("id=\"CCSDS_OMM_VERS\"", out)
    end

    # == NDM wrapper schema (write_odm) ====================================================

    @testset "NDM wrapper schema" begin
        buf = IOBuffer()
        write_odm(buf, omm)
        out = String(take!(buf))
        @test occursin("<ndm", out)
        @test occursin("xsi:noNamespaceSchemaLocation", out)
    end

    # == Vector form =======================================================================

    @testset "Vector form" begin
        buf = IOBuffer()
        write_odm(buf, [omm, omm])
        out = String(take!(buf))
        # Count the number of <omm> elements.
        count_omms = length(collect(eachmatch(r"<omm", out)))
        @test count_omms == 2
    end

    # == Minimal XML (no optional sections) ================================================

    @testset "Minimal XML" begin
        minimal = OrbitMeanElementsMessage(;
            creation_date        = NanoDate("2025-01-01T00:00:00"),
            originator           = "T",
            object_name          = "SAT",
            object_id            = "2025-001A",
            center_name          = "EARTH",
            ref_frame            = "TEME",
            time_system          = "UTC",
            mean_element_theory  = "SGP4",
            epoch                = NanoDate("2025-01-01T00:00:00"),
            mean_motion          = 15.0,
            eccentricity         = 0.0,
            inclination          = 0.0,
            raan                 = 0.0,
            arg_of_pericenter    = 0.0,
            mean_anomaly         = 0.0,
        )

        buf = IOBuffer()
        write_omm(buf, minimal)
        out = String(take!(buf))

        # No spacecraftParameters / tleParameters / userDefinedParameters sections.
        @test !occursin("spacecraftParameters", out)
        @test !occursin("tleParameters", out)
        @test !occursin("userDefinedParameters", out)
    end

    # == user_defined attributes ===========================================================

    @testset "user_defined attributes" begin
        minimal = OrbitMeanElementsMessage(;
            creation_date        = NanoDate("2025-01-01T00:00:00"),
            originator           = "T",
            object_name          = "SAT",
            object_id            = "2025-001A",
            center_name          = "EARTH",
            ref_frame            = "TEME",
            time_system          = "UTC",
            mean_element_theory  = "SGP4",
            epoch                = NanoDate("2025-01-01T00:00:00"),
            mean_motion          = 15.0,
            eccentricity         = 0.0,
            inclination          = 0.0,
            raan                 = 0.0,
            arg_of_pericenter    = 0.0,
            mean_anomaly         = 0.0,
            user_defined_parameters = ["MY_KEY" => "my_value"],
        )

        buf = IOBuffer()
        write_omm(buf, minimal)
        out = String(take!(buf))

        @test occursin("userDefinedParameters", out)
        @test occursin("USER_DEFINED", out)
        @test occursin("parameter=\"MY_KEY\"", out)
        @test occursin("my_value", out)
    end

    # == Compare Against Reference File ====================================================

    @testset "Compare Against Reference File" begin
        vodm = read_odm("ndm_example.xml")
        outfile, _ = mktemp()
        write_odm(outfile, vodm)
        vret = read_odm(outfile)

        @test vret == vodm
    end
end
