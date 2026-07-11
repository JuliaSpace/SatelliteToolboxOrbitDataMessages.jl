## Description #############################################################################
#
# Tests for the two CCSDS date/time formats: calendar (YYYY-MM-DDT...) and ordinal
# day-of-year (YYYY-DDDT...).
#
############################################################################################

@testset "Date Formats" verbose = true begin
    @testset "Calendar Format (YYYY-MM-DDThh:mm:ss[.d→d][Z])" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-12-30T23:36:37",
            epoch         = "2025-12-30T18:12:04.533984",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-30T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    end

    @testset "Calendar Format With Z Suffix" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-12-30T23:36:37Z",
            epoch         = "2025-12-30T18:12:04.533984Z",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-30T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    end

    @testset "Ordinal Day-of-Year Format (YYYY-DDDThh:mm:ss[.d→d][Z])" begin
        # 2025-365 = 2025-12-31.
        xml = _minimal_omm_xml(;
            creation_date = "2025-365T23:36:37",
            epoch         = "2025-365T18:12:04.533984",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-31T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-31T18:12:04.533984")
    end

    @testset "Ordinal Day-of-Year Format With Z Suffix" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-365T23:36:37Z",
            epoch         = "2025-365T18:12:04.533984Z",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-31T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-31T18:12:04.533984")
    end

    @testset "Ordinal Day 001 = January 1" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-001T00:00:00",
            epoch         = "2025-001T00:00:00",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-01-01T00:00:00")
        @test omm.body.segment.data.epoch == NanoDate("2025-01-01T00:00:00")
    end

    @testset "Leap Year Day 366 = December 31" begin
        # 2024 is a leap year; 2024-366 = 2024-12-31.
        xml = _minimal_omm_xml(;
            creation_date = "2024-366T12:00:00",
            epoch         = "2024-366T12:00:00",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2024-12-31T12:00:00")
        @test omm.body.segment.data.epoch == NanoDate("2024-12-31T12:00:00")
    end

    @testset "Invalid Ordinal Days" begin
        @test_throws ArgumentError parse_omm(_minimal_omm_xml(epoch = "2025-000T00:00:00"))
        @test_throws ArgumentError parse_omm(_minimal_omm_xml(epoch = "2025-366T00:00:00"))
        @test_throws ArgumentError parse_omm(_minimal_omm_xml(epoch = "2024-367T00:00:00"))
    end

    @testset "Empty Dates" begin
        creation_xml = replace(
            _minimal_omm_xml(),
            "<CREATION_DATE>2025-12-30T23:36:37</CREATION_DATE>" =>
                "<CREATION_DATE></CREATION_DATE>",
        )
        epoch_xml = replace(
            _minimal_omm_xml(),
            "<EPOCH>2025-12-30T18:12:04.533984</EPOCH>" => "<EPOCH></EPOCH>",
        )

        @test_throws ArgumentError parse_omm(creation_xml)
        @test_throws ArgumentError parse_omm(epoch_xml)

        permissive_omm = parse_omm(creation_xml; strict = false)
        @test isnothing(permissive_omm.header.creation_date)
        @test_throws ArgumentError write_omm(IOBuffer(), permissive_omm)
    end

    @testset "Ordinal Format Without Fractional Seconds" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-060T12:30:45",
            epoch         = "2025-060T12:30:45",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        # 2025-060 = 2025-03-01 (non-leap year).
        @test omm.header.creation_date == NanoDate("2025-03-01T12:30:45")
        @test omm.body.segment.data.epoch == NanoDate("2025-03-01T12:30:45")
    end

    @testset "Ref Frame Epoch in Ordinal Format" begin
        xml = _minimal_omm_xml(;
            ref_frame_epoch = "2025-200T00:00:00",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        # 2025-200 = 2025-07-19.
        @test omm.body.segment.metadata.ref_frame_epoch == NanoDate("2025-07-19T00:00:00")
    end

    @testset "Round-Trip Preserves Calendar Format Values" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-365T23:36:37Z",
            epoch         = "2025-365T18:12:04.533984Z",
        )
        omm = parse_omm(xml)

        buf = IOBuffer()
        write_omm(buf, omm)
        written_xml = String(take!(buf))

        omm_reparsed = parse_omm(written_xml)

        @test !isnothing(omm_reparsed)
        @test omm_reparsed.header.creation_date == omm.header.creation_date
        @test omm_reparsed.body.segment.data.epoch == omm.body.segment.data.epoch
    end

    @testset "Nanosecond Round-Trip" begin
        epoch = NanoDate("2025-12-30T18:12:04.123456789")
        omm = parse_omm(_minimal_omm_xml(epoch = string(epoch)))
        buf = IOBuffer()
        write_omm(buf, omm)

        @test parse_omm(String(take!(buf))).body.segment.data.epoch == epoch
    end
end
