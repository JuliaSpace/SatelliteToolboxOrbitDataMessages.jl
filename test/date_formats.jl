## Description #############################################################################
#
# Tests for the two CCSDS date/time formats: calendar (YYYY-MM-DDT...) and ordinal
# day-of-year (YYYY-DDDT...).
#
############################################################################################

@testset "Date formats" verbose = true begin
    @testset "Calendar format (YYYY-MM-DDThh:mm:ss[.d→d][Z])" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-12-30T23:36:37",
            epoch         = "2025-12-30T18:12:04.533984",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-30T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    end

    @testset "Calendar format with Z suffix" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-12-30T23:36:37Z",
            epoch         = "2025-12-30T18:12:04.533984Z",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-30T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    end

    @testset "Ordinal day-of-year format (YYYY-DDDThh:mm:ss[.d→d][Z])" begin
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

    @testset "Ordinal day-of-year format with Z suffix" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-365T23:36:37Z",
            epoch         = "2025-365T18:12:04.533984Z",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-12-31T23:36:37")
        @test omm.body.segment.data.epoch == NanoDate("2025-12-31T18:12:04.533984")
    end

    @testset "Ordinal day 001 = January 1" begin
        xml = _minimal_omm_xml(;
            creation_date = "2025-001T00:00:00",
            epoch         = "2025-001T00:00:00",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test omm.header.creation_date == NanoDate("2025-01-01T00:00:00")
        @test omm.body.segment.data.epoch == NanoDate("2025-01-01T00:00:00")
    end

    @testset "Leap year day 366 = December 31" begin
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

    @testset "Ordinal format without fractional seconds" begin
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

    @testset "Ref frame epoch in ordinal format" begin
        xml = _minimal_omm_xml(;
            ref_frame_epoch = "2025-200T00:00:00",
        )
        omm = parse_omm(xml)

        @test !isnothing(omm)
        # 2025-200 = 2025-07-19.
        @test omm.body.segment.metadata.ref_frame_epoch == NanoDate("2025-07-19T00:00:00")
    end

    @testset "Round-trip preserves calendar format values" begin
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
end
