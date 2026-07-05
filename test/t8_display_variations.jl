## Description #############################################################################
#
# T8 — Show/display variation tests.
#
############################################################################################

@testset "T8: Display variations" verbose = true begin
    creation_date = NanoDate("2025-12-30T23:36:37")
    epoch         = NanoDate("2025-12-30T18:12:04.533984")

    # == T8.3: Spacecraft parameters populated ===========================================

    @testset "T8.3: Spacecraft parameters shown" begin
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

    # == T8.4: No TLE parameters -> section omitted ======================================

    @testset "T8.4: No TLE parameters" begin
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
            eccentricity         = 0.001,
            inclination          = 45.0,
            raan                 = 100.0,
            arg_of_pericenter    = 50.0,
            mean_anomaly         = 200.0,
        )

        result = sprint(show, MIME("text/plain"), omm)
        @test !occursin("TLE Related Parameters", result)
    end

    # == T8.5: mean_motion_dot = nothing -> row omitted ==================================

    @testset "T8.5: Omitted rows" begin
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

    # == T8.6: No user-defined parameters -> section omitted =============================

    @testset "T8.6: No user-defined parameters" begin
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
            eccentricity         = 0.001,
            inclination          = 45.0,
            raan                 = 100.0,
            arg_of_pericenter    = 50.0,
            mean_anomaly         = 200.0,
        )

        result = sprint(show, MIME("text/plain"), omm)
        @test !occursin("User-Defined Parameters", result)
    end

    # == T8.7: Color smoke test ==========================================================

    @testset "T8.7: Color output" begin
        omm = read_omm(_FIXTURE_FILE)

        buf = IOContext(IOBuffer(), :color => true)
        show(buf, MIME("text/plain"), omm)
        result = String(take!(buf.io))

        # ANSI escape codes should be present when color is enabled.
        @test occursin("\e[", result)
    end
end
