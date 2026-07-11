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

    # == Spacecraft Parameters Populated ===================================================

    creation_date = NanoDate("2025-12-30T23:36:37")
    epoch         = NanoDate("2025-12-30T18:12:04.533984")

    @testset "Spacecraft Parameters Shown" begin
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

    # == No TLE Parameters -> Section Omitted ==============================================

    @testset "No TLE Parameters" begin
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

    # == mean_motion_dot = nothing -> Row Omitted ==========================================

    @testset "Omitted Rows" begin
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

    # == No User-Defined Parameters -> Section Omitted =====================================

    @testset "No User-Defined Parameters" begin
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

    # == Fully Populated Display ========================================================

    @testset "All Optional Sections" begin
        covariance_matrix = OmmCovarianceMatrix(;
            comments = ["Covariance comment"],
            cov_ref_frame = "RTN",
            cx_x = 1.0,
            cy_x = 2.0,
            cy_y = 3.0,
            cz_x = 4.0,
            cz_y = 5.0,
            cz_z = 6.0,
            cx_dot_x = 7.0,
            cx_dot_y = 8.0,
            cx_dot_z = 9.0,
            cx_dot_x_dot = 10.0,
            cy_dot_x = 11.0,
            cy_dot_y = 12.0,
            cy_dot_z = 13.0,
            cy_dot_x_dot = 14.0,
            cy_dot_y_dot = 15.0,
            cz_dot_x = 16.0,
            cz_dot_y = 17.0,
            cz_dot_z = 18.0,
            cz_dot_x_dot = 19.0,
            cz_dot_y_dot = 20.0,
            cz_dot_z_dot = 21.0,
        )

        omm = OrbitMeanElementsMessage(;
            header_comments = ["Header comment 1", "Header comment 2"],
            classification = "UNCLASSIFIED",
            creation_date,
            originator = "TEST",
            message_id = "MESSAGE-1",
            metadata_comments = ["Metadata comment"],
            object_name = "TEST SAT",
            object_id = "2025-001A",
            center_name = "EARTH",
            ref_frame = "TEME",
            ref_frame_epoch = NanoDate("2025-01-01T00:00:00.123456789"),
            time_system = "UTC",
            mean_element_theory = "SGP4",
            data_comments = ["Data comment\nsecond line"],
            mean_elements_comments = ["Mean elements comment"],
            epoch,
            semi_major_axis = 7000.0,
            eccentricity = 0.001,
            inclination = 45.0,
            raan = 100.0,
            arg_of_pericenter = 50.0,
            mean_anomaly = 200.0,
            GM = 398600.4418,
            spacecraft_parameters_comments = ["Spacecraft comment"],
            mass = 100.0,
            solar_rad_area = 3.0,
            solar_rad_coeff = 1.2,
            drag_area = 2.0,
            drag_coeff = 2.2,
            tle_parameters_comments = ["TLE comment"],
            ephemeris_type = 0,
            classification_type = 'U',
            norad_cat_id = 12345,
            element_set_number = 12,
            rev_at_epoch = 34,
            bterm = 0.01,
            mean_motion_dot = 1e-5,
            agom = 0.02,
            covariance_matrix,
            user_defined_parameters = ["KEY" => "VALUE"],
        )

        result = sprint(show, MIME("text/plain"), omm)

        for expected_line in (
            "Comment        : Header comment 1",
            "Comment        : Header comment 2",
            "Classification : UNCLASSIFIED",
            "Message ID     : MESSAGE-1",
            "Comment             : Metadata comment",
            "Ref. Frame Epoch    : 2025-01-01T00:00:00.123456789",
            "        Comment : Data comment\\nsecond line",
            "Comment            : Mean elements comment",
            "Semi-Major Axis    : 7000.0 km",
            "GM                 : 398600.4418 km³/s²",
            "Comment           : Spacecraft comment",
            "Solar Rad. Area   : 3.0 m²",
            "Solar Rad. Coeff. : 1.2",
            "Drag Area         : 2.0 m²",
            "Drag Coefficient  : 2.2",
            "Comment             : TLE comment",
            "Bterm               : 0.01 m²/kg",
            "AGOM                : 0.02 m²/kg",
            "Comment      : Covariance comment",
            "Ref. Frame   : RTN",
            "CZ_DOT_Z_DOT : 21.0 km²/s²",
            "KEY : VALUE",
        )
            @test occursin(expected_line, result)
        end

        section_positions = map(
            section -> findfirst(section, result),
            (
                "├─ Mean Keplerian Elements",
                "├─ Spacecraft Parameters",
                "├─ TLE Related Parameters",
                "├─ Covariance Matrix",
                "└─ User-Defined Parameters",
            ),
        )
        @test all(!isnothing, section_positions)
        @test issorted(first.(section_positions))
        @test !occursin("Mean Motion        :", result)
        @test !occursin("Bstar", result)
        @test !occursin("∂²(Mean Motion)/∂t²", result)
    end

    # == Color Smoke Test ==================================================================

    @testset "Color Output" begin
        omm = read_omm(_FIXTURE_FILE)

        buf = IOContext(IOBuffer(), :color => true)
        show(buf, MIME("text/plain"), omm)
        result = String(take!(buf.io))

        # ANSI escape codes should be present when color is enabled.
        @test occursin("\e[", result)
    end
end
