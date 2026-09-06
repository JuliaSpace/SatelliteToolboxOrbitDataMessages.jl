## Description #############################################################################
#
# Write output structure tests.
#
############################################################################################

@testset "Write Structure" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == XML Declaration ===================================================================

    @testset "XML Declaration" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))
        @test startswith(out, "<?xml")
        @test occursin("encoding=\"UTF-8\"", out)
    end

    # == OMM Root Version ==================================================================

    @testset "OMM Root Version" begin
        buf = IOBuffer()
        write_omm(buf, omm)
        out = String(take!(buf))
        @test occursin("<omm", out)
        @test occursin("version=\"3.0\"", out)
        @test occursin("id=\"CCSDS_OMM_VERS\"", out)
    end

    # == NDM Wrapper Schema (write_odm) ====================================================

    @testset "NDM Wrapper Schema" begin
        buf = IOBuffer()
        write_odm(buf, omm)
        out = String(take!(buf))
        @test occursin("<ndm", out)
        @test occursin("xsi:noNamespaceSchemaLocation", out)
    end

    # == Vector Form =======================================================================

    @testset "Vector Form" begin
        buf = IOBuffer()
        write_odm(buf, [omm, omm])
        out = String(take!(buf))
        # Count the number of <omm> elements.
        count_omms = length(collect(eachmatch(r"<omm", out)))
        @test count_omms == 2
    end

    # == Failed Writes Preserve the Output File ============================================

    @testset "Failed Writes Preserve the Output File" begin
        mktempdir() do dir
            file = joinpath(dir, "omm.xml")
            write(file, "precious content")

            # An unsupported format must not truncate the file.
            @test_throws ArgumentError write_omm(file, omm; format = :json)
            @test read(file, String) == "precious content"

            # A message that cannot be written must not truncate the file.
            omm_lenient = parse_omm(_minimal_omm_xml(; creation_date = ""))

            @test_throws ArgumentError write_omm(file, omm_lenient)
            @test read(file, String) == "precious content"

            @test_throws ArgumentError write_odm(file, omm_lenient)
            @test read(file, String) == "precious content"

            @test_throws ArgumentError write_odm(file, [omm_lenient])
            @test read(file, String) == "precious content"
        end
    end

    # == Invalid User-Defined Keys in KVN ==================================================

    @testset "Invalid User-Defined Keys in KVN" begin
        omm_bad = OrbitMeanElementsMessage(
            omm; user_defined_parameters = ["bad key" => "1"]
        )

        # A name outside the KVN keyword grammar cannot be written back, so it must be
        # rejected instead of producing an unparseable file.
        @test_throws ArgumentError write_omm(IOBuffer(), omm_bad; format = :kvn)

        # The XML format accepts arbitrary parameter names.
        buf = IOBuffer()
        write_omm(buf, omm_bad)
        @test occursin("bad key", String(take!(buf)))

        # The file method must reject the message before truncating the target.
        mktempdir() do dir
            file = joinpath(dir, "omm.kvn")
            write(file, "precious content")
            @test_throws ArgumentError write_omm(file, omm_bad)
            @test read(file, String) == "precious content"
        end
    end

    # == Minimal XML (no optional sections) ================================================

    @testset "Minimal XML" begin
        minimal = OrbitMeanElementsMessage(;
            creation_date       = NanoDate("2025-01-01T00:00:00"),
            originator          = "T",
            object_name         = "SAT",
            object_id           = "2025-001A",
            center_name         = "EARTH",
            ref_frame           = "TEME",
            time_system         = "UTC",
            mean_element_theory = "SGP4",
            epoch               = NanoDate("2025-01-01T00:00:00"),
            mean_motion         = 15.0,
            eccentricity        = 0.0,
            inclination         = 0.0,
            raan                = 0.0,
            arg_of_pericenter   = 0.0,
            mean_anomaly        = 0.0,
        )

        buf = IOBuffer()
        write_omm(buf, minimal)
        out = String(take!(buf))

        # No spacecraftParameters / tleParameters / userDefinedParameters sections.
        @test !occursin("spacecraftParameters", out)
        @test !occursin("tleParameters", out)
        @test !occursin("userDefinedParameters", out)
    end

    # == user_defined Attributes ===========================================================

    @testset "user_defined Attributes" begin
        minimal = OrbitMeanElementsMessage(;
            creation_date = NanoDate("2025-01-01T00:00:00"),
            originator = "T",
            object_name = "SAT",
            object_id = "2025-001A",
            center_name = "EARTH",
            ref_frame = "TEME",
            time_system = "UTC",
            mean_element_theory = "SGP4",
            epoch = NanoDate("2025-01-01T00:00:00"),
            mean_motion = 15.0,
            eccentricity = 0.0,
            inclination = 0.0,
            raan = 0.0,
            arg_of_pericenter = 0.0,
            mean_anomaly = 0.0,
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

    # == Escaped Characters ================================================================

    @testset "Escaped Characters" begin
        omm_special = OrbitMeanElementsMessage(
            omm;
            header_comments = ["a < b & c > d \"quoted\""],
            object_name = "SAT <1> & \"2\"",
            classification_type = '<',
            user_defined_parameters = ["A&B<>\"" => "left & right <x>"],
        )

        for messages in (omm_special, [omm_special, omm_special])
            buf = IOBuffer()
            write_omm(buf, messages)
            out = String(take!(buf))

            @test !occursin("<1>", out)
            @test occursin("&lt;1&gt; &amp; &quot;2&quot;", out)
            @test occursin("parameter=\"A&amp;B&lt;&gt;&quot;\"", out)
            @test endswith(out, "\n")

            reparsed = parse_omms(out)
            @test all(==(omm_special), reparsed)
            @test length(reparsed) == length(messages isa AbstractVector ? messages : [1])
        end
    end

    # == Compare Against Reference File ====================================================

    @testset "Compare Against Reference File" begin
        # == OMM ===========================================================================

        omm = read_omm(_FIXTURE_FILE)
        outfile, _ = mktemp()
        write_omm(outfile, omm)
        ret = read_omm(outfile)

        @test ret == omm

        # == ODM ===========================================================================

        vodm = read_odm(_NDM_FIXTURE_FILE)
        outfile, _ = mktemp()
        write_odm(outfile, vodm)
        vret = read_odm(outfile)

        @test vret == vodm

        outfile, _ = mktemp()
        write_odm(outfile, first(vodm))
        vret = read_odm(outfile)
        @test first(vret) == first(vodm)
    end
end
