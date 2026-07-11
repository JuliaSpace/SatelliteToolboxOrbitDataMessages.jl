## Description #############################################################################
#
# convert(TLE, omm) extension tests.
#
############################################################################################

@testset "TLE Extension" verbose = true begin
    omm = read_omm(_FIXTURE_FILE)

    # == Convert Fixture OMM to TLE ========================================================

    @testset "Convert Fixture" begin
        tle = convert(TLE, omm)

        @test tle isa TLE
        @test tle.name == "AMAZONIA 1"
        @test tle.satellite_number == 47699
        @test tle.classification == 'U'
        @test tle.international_designator == "21015A"
        @test tle.epoch_year == 25
        @test tle.mean_motion ≈ 14.40772474 atol = 1e-6
        @test tle.eccentricity ≈ 0.00011240 atol = 1e-8
        @test tle.inclination ≈ 98.3721 atol = 1e-4
        @test tle.raan ≈ 75.0877 atol = 1e-4
        @test tle.argument_of_perigee ≈ 97.3772 atol = 1e-4
        @test tle.mean_anomaly ≈ 262.7545 atol = 1e-4
        @test tle.bstar ≈ 0.00015330000000 atol = 1e-12
        @test tle.element_set_number == 999
        @test tle.revolution_number == 25439
    end

    # == Non-SGP4 Mean Element Theory ======================================================

    @testset "Non-SGP4 Theory" begin
        bad_omm = OrbitMeanElementsMessage(omm; mean_element_theory = "SPECIAL")
        @test_throws ErrorException convert(TLE, bad_omm)
    end

    # == Missing mean_motion and semi_major_axis ===========================================

    @testset "Missing Mean Motion Fields" begin
        @test_throws ArgumentError OrbitMeanElementsMessage(
            omm;
            mean_motion = nothing,
            semi_major_axis = nothing,
            GM = nothing,
        )
    end

    # == Computed Mean Motion From semi_major_axis and GM ==================================

    @testset "Computed Mean Motion" begin
        a  = 7134.084
        GM = 398600.4418
        expected_n = sqrt(GM / a^3) / (2π) * 86400

        omm_computed = OrbitMeanElementsMessage(omm;
            mean_motion      = nothing,
            semi_major_axis  = a,
            GM               = GM,
        )

        tle = convert(TLE, omm_computed)
        @test tle.mean_motion ≈ expected_n atol = 1e-6
    end

    # == Missing norad_cat_id ==============================================================

    @testset "Default norad_cat_id" begin
        omm_no_norad = OrbitMeanElementsMessage(omm; norad_cat_id = nothing)
        @test_throws ErrorException convert(TLE, omm_no_norad)
    end

    # == International Designator Conversion ===============================================

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
end
