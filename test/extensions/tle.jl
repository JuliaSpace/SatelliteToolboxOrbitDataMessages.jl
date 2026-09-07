## Description #############################################################################
#
# Tests of the conversions between OMMs and TLEs provided by the SatelliteToolboxTle
# extension.
#
############################################################################################

# Keywords of the TLE related to the Amazonia 1 fixture OMM, whose elements are the same.
const _FIXTURE_TLE_KWARGS = (;
    name                     = "AMAZONIA 1",
    satellite_number         = 47699,
    classification           = 'U',
    international_designator = "21015A",
    epoch_year               = 25,
    epoch_day                = 364.75838581,
    dn_o2                    = 0.00000447,
    ddn_o6                   = 0.0,
    bstar                    = 0.0001533,
    ephemeris_type           = 0,
    element_set_number       = 999,
    inclination              = 98.3721,
    raan                     = 75.0877,
    eccentricity             = 0.00011240,
    argument_of_perigee      = 97.3772,
    mean_anomaly             = 262.7545,
    mean_motion              = 14.40772474,
    revolution_number        = 25439,
)

"""
    _fixture_tle(; kwargs...) -> TLE

Return the TLE related to the Amazonia 1 fixture OMM, overriding the fields in `kwargs...`.
"""
_fixture_tle(; kwargs...) = TLE(; _FIXTURE_TLE_KWARGS..., kwargs...)

@testset "TLE Extension" verbose = true begin
    omm         = read_omm(_FIXTURE_FILE)
    fixture_tle = _fixture_tle()

    # == OMM to TLE ========================================================================

    @testset "Convert Fixture" begin
        tle = convert(TLE, omm)

        @test tle isa TLE
        @test tle.name == "AMAZONIA 1"
        @test tle.satellite_number == 47699
        @test tle.classification == 'U'
        @test tle.international_designator == "21015A"
        @test tle.epoch_year == 25
        @test tle.epoch_day ≈ 364.75838581 atol = 1e-12
        @test tle.ephemeris_type == 0
        @test tle.mean_motion ≈ 14.40772474 atol = 1e-6
        @test tle.eccentricity ≈ 0.00011240 atol = 1e-8
        @test tle.inclination ≈ 98.3721 atol = 1e-4
        @test tle.raan ≈ 75.0877 atol = 1e-4
        @test tle.argument_of_perigee ≈ 97.3772 atol = 1e-4
        @test tle.mean_anomaly ≈ 262.7545 atol = 1e-4
        @test tle.bstar ≈ 0.00015330000000 atol = 1e-12
        @test tle.dn_o2 ≈ 0.00000447 atol = 1e-12
        @test tle.ddn_o6 == 0.0
        @test tle.element_set_number == 999
        @test tle.revolution_number == 25439
    end

    @testset "Non-SGP4 Theory" begin
        bad_omm = OrbitMeanElementsMessage(omm; mean_element_theory = "SPECIAL")
        @test_throws ErrorException convert(TLE, bad_omm)
    end

    @testset "Missing Mean Motion Fields" begin
        @test_throws ArgumentError OrbitMeanElementsMessage(
            omm; mean_motion = nothing, semi_major_axis = nothing, GM = nothing
        )
    end

    @testset "Computed Mean Motion" begin
        a  = 7134.084
        GM = 398600.4418
        expected_n = sqrt(GM / a^3) / (2π) * 86400

        omm_computed = OrbitMeanElementsMessage(
            omm; mean_motion = nothing, semi_major_axis = a, GM = GM
        )

        tle = convert(TLE, omm_computed)
        @test tle.mean_motion ≈ expected_n atol = 1e-6

        # The gravitational parameter is required to compute the mean motion.
        omm_no_gm = OrbitMeanElementsMessage(
            omm; mean_motion = nothing, semi_major_axis = a
        )
        @test_throws ErrorException convert(TLE, omm_no_gm)
    end

    @testset "Missing TLE Parameters" begin
        for field in (
            :classification_type,
            :norad_cat_id,
            :element_set_number,
            :rev_at_epoch,
        )
            omm_missing = OrbitMeanElementsMessage(omm; field => nothing)
            @test_throws ErrorException convert(TLE, omm_missing)
        end

        # The alternative drag and solar radiation pressure parameters have no TLE
        # representation.
        omm_bterm = OrbitMeanElementsMessage(omm; bstar = nothing, bterm = 0.01)
        @test_throws ErrorException convert(TLE, omm_bterm)

        omm_agom = OrbitMeanElementsMessage(omm; mean_motion_ddot = nothing, agom = 0.01)
        @test_throws ErrorException convert(TLE, omm_agom)
    end

    @testset "Ephemeris Type" begin
        tle = convert(TLE, OrbitMeanElementsMessage(omm; ephemeris_type = 2))
        @test tle.ephemeris_type == 2

        # The ephemeris type is optional in the OMM and defaults to 0 in the TLE.
        tle = convert(TLE, OrbitMeanElementsMessage(omm; ephemeris_type = nothing))
        @test tle.ephemeris_type == 0
    end

    @testset "Epoch Range" begin
        # The two-digit TLE year can only represent the years from 1957 to 2056.
        for epoch in (NanoDate("1956-12-31T23:59:59.999"), NanoDate("2057-01-01T00:00:00"))
            omm_epoch = OrbitMeanElementsMessage(omm; epoch)
            @test_throws ErrorException convert(TLE, omm_epoch)
        end

        omm_epoch = OrbitMeanElementsMessage(omm; epoch = NanoDate("1957-01-01T12:00:00"))
        tle = convert(TLE, omm_epoch)
        @test tle.epoch_year == 57
        @test tle.epoch_day == 1.5

        # 2056 is a leap year, so December 31 is the day 366.
        omm_epoch = OrbitMeanElementsMessage(omm; epoch = NanoDate("2056-12-31T00:00:00"))
        tle = convert(TLE, omm_epoch)
        @test tle.epoch_year == 56
        @test tle.epoch_day == 366.0
    end

    @testset "Designator 2021-015A" begin
        omm_designator = OrbitMeanElementsMessage(omm; object_id = "2021-015A")
        tle = convert(TLE, omm_designator)
        @test tle.international_designator == "21015A"
    end

    @testset "Designator 2021-15" begin
        omm_designator = OrbitMeanElementsMessage(omm; object_id = "2021-15")
        tle = convert(TLE, omm_designator)
        @test tle.international_designator == "21015"
    end

    @testset "Designator Fallback" begin
        omm_designator = OrbitMeanElementsMessage(omm; object_id = " UNKNOWN ")
        tle = convert(TLE, omm_designator)
        @test tle.international_designator == "UNKNOWN"
    end

    # == TLE to OMM ========================================================================

    @testset "Create From Fixture TLE" begin
        omm_tle = OrbitMeanElementsMessage(fixture_tle)

        @test omm_tle isa OrbitMeanElementsMessage
        @test omm_tle.version == v"3.0"

        # The header is generated by the conversion.
        @test isempty(omm_tle.header.comments)
        @test isnothing(omm_tle.classification)
        @test omm_tle.creation_date isa NanoDate
        @test Dates.value(NanoDate(now(UTC)) - omm_tle.creation_date) < 60 * 10^9
        @test startswith(omm_tle.originator, "SatelliteToolboxOrbitDataMessages.jl v")
        @test isnothing(omm_tle.message_id)

        # The metadata and the data must match the fixture, except for the user-defined
        # parameters that the TLE does not carry.
        @test omm_tle.metadata == omm.metadata
        @test omm_tle.data ==
            OmmData(omm.data; user_defined_parameters = Pair{String, String}[])

        # `convert` uses the default header.
        omm_converted = convert(OrbitMeanElementsMessage, fixture_tle)
        @test omm_converted.metadata == omm_tle.metadata
        @test omm_converted.data == omm_tle.data
        @test omm_converted.originator == omm_tle.originator
    end

    @testset "Keyword Overrides" begin
        omm_tle = OrbitMeanElementsMessage(
            fixture_tle;
            header_comments = ["GENERATED FROM A TLE"],
            classification  = "UNCLASSIFIED",
            creation_date   = NanoDate("2025-12-30T23:36:37"),
            originator      = "TEST",
            message_id      = "MSG-1",
            object_name     = "AMAZONIA-1",
            ref_frame       = "TEME2",
            mean_motion_dot = 1e-6,
        )

        @test omm_tle.header.comments == ["GENERATED FROM A TLE"]
        @test omm_tle.classification == "UNCLASSIFIED"
        @test omm_tle.creation_date == NanoDate("2025-12-30T23:36:37")
        @test omm_tle.originator == "TEST"
        @test omm_tle.message_id == "MSG-1"
        @test omm_tle.object_name == "AMAZONIA-1"
        @test omm_tle.ref_frame == "TEME2"
        @test omm_tle.mean_motion_dot == 1e-6

        # The overrides are validated as in the keyword constructor.
        @test_throws ArgumentError OrbitMeanElementsMessage(
            fixture_tle; semi_major_axis = 7134.0
        )
        @test_throws ArgumentError OrbitMeanElementsMessage(fixture_tle; version = v"1.0")
    end

    @testset "Epoch Conversion" begin
        # The day of the year starts at 1.
        tle = _fixture_tle(; epoch_year = 25, epoch_day = 1.5)
        @test OrbitMeanElementsMessage(tle).epoch == NanoDate("2025-01-01T12:00:00")

        # Leap years are taken into account.
        tle = _fixture_tle(; epoch_year = 24, epoch_day = 60.0)
        @test OrbitMeanElementsMessage(tle).epoch == NanoDate("2024-02-29T00:00:00")

        # The sub-millisecond part of the day fraction is preserved.
        tle = _fixture_tle(; epoch_year = 25, epoch_day = 100.12345678)
        @test OrbitMeanElementsMessage(tle).epoch == NanoDate("2025-04-10T02:57:46.665792")

        # Years from 57 to 99 refer to the 20th century, and years from 0 to 56 to the 21st
        # century.
        for (epoch_year, expected_year) in ((0, 2000), (56, 2056), (57, 1957), (99, 1999))
            tle = _fixture_tle(; epoch_year, epoch_day = 1.0)
            @test OrbitMeanElementsMessage(tle).epoch == NanoDate(expected_year)
        end
    end

    @testset "Designator Conversion" begin
        for (intl_designator, expected_object_id) in (
            "21015A"    => "2021-015A",
            "98067A"    => "1998-067A",
            "98067BCD"  => "1998-067BCD",
            "21015"     => "2021-015",
            "2115A"     => "2021-015A",
            "57001A"    => "1957-001A",
            "56001A"    => "2056-001A",
            "00000"     => "2000-000",
            " 21015A "  => "2021-015A",
            "UNKNOWN"   => "UNKNOWN",
            "2021-15A"  => "2021-15A",
            "21015a"    => "21015a",
        )
            tle = _fixture_tle(; international_designator = intl_designator)
            @test OrbitMeanElementsMessage(tle).object_id == expected_object_id
        end
    end

    # == Round Trips =======================================================================

    @testset "Round Trip OMM → TLE → OMM" begin
        # The conversion from TLE cannot recover the header and the user-defined
        # parameters, which are copied from the fixture.
        omm_round_trip = OrbitMeanElementsMessage(
            convert(TLE, omm);
            header_comments         = omm.header.comments,
            creation_date           = omm.creation_date,
            originator              = omm.originator,
            user_defined_parameters = omm.user_defined_parameters,
        )

        @test omm_round_trip == omm
    end

    @testset "Round Trip TLE → OMM → TLE" begin
        tle_round_trip = convert(TLE, OrbitMeanElementsMessage(fixture_tle))

        for field in fieldnames(TLE)
            expected = getfield(fixture_tle, field)
            obtained = getfield(tle_round_trip, field)

            if field === :epoch_day
                # The epoch is rounded to the microsecond when creating the message.
                @test obtained ≈ expected atol = 1e-11
            else
                @test obtained == expected
            end
        end

        # The TLE text, which has the precision of the TLE format, must be identical.
        @test write_tle(String, tle_round_trip) == write_tle(String, fixture_tle)
    end
end
