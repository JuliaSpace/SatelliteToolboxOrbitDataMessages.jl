## Description #############################################################################
#
# Show/display tests.
#
############################################################################################

@testset "Display" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == Compact Display ===================================================================

    result   = sprint(show, omm)
    expected = "OMM: AMAZONIA 1 [2021-015A] (Epoch = 2025-12-30T18:12:04.533984)"

    @test result == expected

    # == Detailed Display ==================================================================

    expected = """
OrbitMeanElementsMessage:
  Header
    Comment       : GENERATED VIA SPACE-TRACK.ORG API
    Creation Date : 2025-12-30T23:36:37
    Originator    : 18 SPCS
  Body
  └─ Segment
     ├─ Metadata
     │    Object Name         : AMAZONIA 1
     │    Object ID           : 2021-015A
     │    Center Name         : EARTH
     │    Ref. Frame          : TEME
     │    Time System         : UTC
     │    Mean Element Theory : SGP4
     └─ Data
        ├─ Mean Keplerian Elements
        │    Epoch              : 2025-12-30T18:12:04.533984
        │    Mean Motion        : 14.40772474 rev/day
        │    Eccentricity       : 0.0001124
        │    Inclination        : 98.3721°
        │    RA of Asc. Node    : 75.0877°
        │    Arg. of Pericenter : 97.3772°
        │    Mean Anomaly       : 262.7545°
        ├─ TLE Related Parameters
        │    Ephemeris Type      : 0
        │    Classification Type : U
        │    NORAD Cat ID        : 47699
        │    Element Set Number  : 999
        │    Rev at Epoch        : 25439
        │    Bstar               : 0.0001533
        │    ∂(Mean Motion)/∂t   : 4.47e-6 rev/day²
        │    ∂²(Mean Motion)/∂t² : 0.0 rev/day³
        └─ User-Defined Parameters
             SEMIMAJOR_AXIS : 7134.084
             PERIOD         : 99.946
             APOAPSIS       : 756.751
             PERIAPSIS      : 755.147
             OBJECT_TYPE    : PAYLOAD
             RCS_SIZE       : LARGE
             COUNTRY_CODE   : BRAZ
             LAUNCH_DATE    : 2021-02-28
             SITE           : SRI
             DECAY_DATE     :
             FILE           : 4946249
             GP_ID          : 307230979
"""

    result = sprint(show, MIME("text/plain"), omm)
    @test result == expected

    # == Spacecraft parameters populated ===================================================

    creation_date = NanoDate("2025-12-30T23:36:37")
    epoch         = NanoDate("2025-12-30T18:12:04.533984")

    @testset "Spacecraft parameters shown" begin
        omm = OrbitMeanElementsMessage(;
            creation_date        = creation_date,
            originator           = "TEST",
            object_name          = "TEST SAT",
            object_id            = "2025-001A",
            center_name          = "EARTH",
            ref_frame            = "TEME",
            time_system          = "UTC",
            mean_element_theory  = "SGP4",
            epoch                = epoch,
            mean_motion          = 15.0,
            eccentricity         = 0.001,
            inclination          = 45.0,
            raan                 = 100.0,
            arg_of_pericenter    = 50.0,
            mean_anomaly         = 200.0,
            mass                 = 100.0,
            drag_area            = 2.0,
            drag_coeff           = 2.2,
        )

        result = sprint(show, MIME("text/plain"), omm)
        @test occursin("Spacecraft Parameters", result)
        @test occursin("Mass", result)
        @test occursin("100.0", result)
    end

    # == No TLE parameters -> section omitted ==============================================

    @testset "No TLE parameters" begin
        omm = OrbitMeanElementsMessage(;
            creation_date        = creation_date,
            originator           = "TEST",
            object_name          = "TEST SAT",
            object_id            = "2025-001A",
            center_name          = "EARTH",
            ref_frame            = "TEME",
            time_system          = "UTC",
            mean_element_theory  = "SGP4",
            epoch                = epoch,
            mean_motion          = 15.0,
            eccentricity         = 0.001,
            inclination          = 45.0,
            raan                 = 100.0,
            arg_of_pericenter    = 50.0,
            mean_anomaly         = 200.0,
        )

        result = sprint(show, MIME("text/plain"), omm)
        @test !occursin("TLE Related Parameters", result)
    end

    # == mean_motion_dot = nothing -> row omitted ==========================================

    @testset "Omitted rows" begin
        omm = OrbitMeanElementsMessage(;
            creation_date        = creation_date,
            originator           = "TEST",
            object_name          = "TEST SAT",
            object_id            = "2025-001A",
            center_name          = "EARTH",
            ref_frame            = "TEME",
            time_system          = "UTC",
            mean_element_theory  = "SGP4",
            epoch                = epoch,
            mean_motion          = 15.0,
            eccentricity         = 0.001,
            inclination          = 45.0,
            raan                 = 100.0,
            arg_of_pericenter    = 50.0,
            mean_anomaly         = 200.0,
        )

        result = sprint(show, MIME("text/plain"), omm)
        # The mean_motion_dot row should not appear (it is nothing).
        @test !occursin("Mean Motion)/∂t", result)
    end

    # == No user-defined parameters -> section omitted =====================================

    @testset "No user-defined parameters" begin
        omm = OrbitMeanElementsMessage(;
            creation_date        = creation_date,
            originator           = "TEST",
            object_name          = "TEST SAT",
            object_id            = "2025-001A",
            center_name          = "EARTH",
            ref_frame            = "TEME",
            time_system          = "UTC",
            mean_element_theory  = "SGP4",
            epoch                = epoch,
            mean_motion          = 15.0,
            eccentricity         = 0.001,
            inclination          = 45.0,
            raan                 = 100.0,
            arg_of_pericenter    = 50.0,
            mean_anomaly         = 200.0,
        )

        result = sprint(show, MIME("text/plain"), omm)
        @test !occursin("User-Defined Parameters", result)
    end

    # == Color smoke test ==================================================================

    @testset "Color output" begin
        omm = read_omm(_FIXTURE_FILE)

        buf = IOContext(IOBuffer(), :color => true)
        show(buf, MIME("text/plain"), omm)
        result = String(take!(buf.io))

        # ANSI escape codes should be present when color is enabled.
        @test occursin("\e[", result)
    end
end
