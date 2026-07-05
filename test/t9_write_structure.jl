## Description #############################################################################
#
# T9 — Write output structure tests.
#
############################################################################################

@testset "T9: Write structure" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == T9.1: XML declaration ===========================================================

    @testset "T9.1: XML declaration" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))
        @test startswith(out, "<?xml")
        @test occursin("encoding=\"UTF-8\"", out)
    end

    # == T9.2: OMM root version ==========================================================

    @testset "T9.2: OMM root version" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))
        @test occursin("<omm", out)
        @test occursin("version=\"3.0\"", out)
        @test occursin("id=\"CCSDS_OMM_VERS\"", out)
    end

    # == T9.3: NDM wrapper schema (write_odm) ===========================================

    @testset "T9.3: NDM wrapper schema" begin
        buf = IOBuffer()
        write_odm(buf, omm)
        out = String(take!(buf))
        @test occursin("<ndm", out)
        @test occursin("xsi:noNamespaceSchemaLocation", out)
    end

    # == T9.4: Vector form ===============================================================

    @testset "T9.4: Vector form" begin
        buf = IOBuffer()
        write_odm(buf, [omm, omm])
        out = String(take!(buf))
        # Count the number of <omm> elements.
        count_omms = length(collect(eachmatch(r"<omm", out)))
        @test count_omms == 2
    end

    # == T9.5: Minimal XML (no optional sections) =======================================

    @testset "T9.5: Minimal XML" begin
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

    # == T9.6: user_defined attributes ==================================================

    @testset "T9.6: user_defined attributes" begin
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
end
