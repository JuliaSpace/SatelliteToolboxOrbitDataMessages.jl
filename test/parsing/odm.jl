## Description #############################################################################
#
# Test the parsing of Orbit Data Messages (ODM).
#
############################################################################################

@testset "Parse ODM From File" verbose = true begin
    odm = read_odm(_FIXTURE_FILE)

    @test odm isa Vector{OrbitDataMessage}
    @test length(odm) == 1

    omm = first(odm)

    # == Header Fields =====================================================================
    @test omm.version == v"3.0"
    @test omm.header.comments == ["GENERATED VIA SPACE-TRACK.ORG API"]
    @test omm.header.classification === nothing
    @test omm.header.creation_date == NanoDate("2025-12-30T23:36:37")
    @test omm.header.originator == "18 SPCS"
    @test omm.header.message_id === nothing

    # == Metadata Fields ===================================================================
    @test isempty(omm.metadata.comments)
    @test omm.metadata.object_name == "AMAZONIA 1"
    @test omm.metadata.object_id == "2021-015A"
    @test omm.metadata.center_name == "EARTH"
    @test omm.metadata.ref_frame == "TEME"
    @test omm.metadata.ref_frame_epoch === nothing
    @test omm.metadata.time_system == "UTC"
    @test omm.metadata.mean_element_theory == "SGP4"

    # == Data Fields - Mean Keplerian Elements =============================================
    @test isempty(omm.data.comments)
    @test isempty(omm.data.mean_elements_comments)
    @test omm.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    @test omm.data.semi_major_axis === nothing
    @test omm.data.mean_motion ≈ 14.40772474 atol = 1e-6
    @test omm.data.eccentricity ≈ 0.00011240 atol = 1e-8
    @test omm.data.inclination ≈ 98.3721 atol = 1e-4
    @test omm.data.raan ≈ 75.0877 atol = 1e-4
    @test omm.data.arg_of_pericenter ≈ 97.3772 atol = 1e-4
    @test omm.data.mean_anomaly ≈ 262.7545 atol = 1e-4
    @test omm.data.GM === nothing

    # == Data Fields - Spacecraft Data ====================================================
    @test isempty(omm.data.spacecraft_parameters_comments)
    @test omm.data.mass === nothing
    @test omm.data.solar_rad_area === nothing
    @test omm.data.solar_rad_coeff === nothing
    @test omm.data.drag_area === nothing
    @test omm.data.drag_coeff === nothing

    # == Data Fields - TLE Related Parameters ==============================================
    @test isempty(omm.data.tle_parameters_comments)
    @test omm.data.ephemeris_type == 0
    @test omm.data.classification_type == 'U'
    @test omm.data.norad_cat_id == 47699
    @test omm.data.element_set_number == 999
    @test omm.data.rev_at_epoch == 25439
    @test omm.data.bstar ≈ 0.00015330000000 atol = 1e-12
    @test omm.data.mean_motion_dot ≈ 0.00000447 atol = 1e-9
    @test omm.data.mean_motion_ddot ≈ 0.0 atol = 1e-13

    # == Data Fields - User-Defined Parameters ============================================
    @test length(omm.data.user_defined_parameters) == 12

    # Check some specific user-defined parameters
    user_params = Dict(omm.data.user_defined_parameters)

    @test user_params["SEMIMAJOR_AXIS"] == "7134.084"
    @test user_params["PERIOD"] == "99.946"
    @test user_params["APOAPSIS"] == "756.751"
    @test user_params["PERIAPSIS"] == "755.147"
    @test user_params["OBJECT_TYPE"] == "PAYLOAD"
    @test user_params["RCS_SIZE"] == "LARGE"
    @test user_params["COUNTRY_CODE"] == "BRAZ"
    @test user_params["LAUNCH_DATE"] == "2021-02-28"
    @test user_params["SITE"] == "SRI"
    @test user_params["DECAY_DATE"] == ""
    @test user_params["FILE"] == "4946249"
    @test user_params["GP_ID"] == "307230979"
end

@testset "Parse ODM From IO" verbose = true begin
    io = open(_FIXTURE_FILE, "r")
    odm = read_odm(io)

    @test odm isa Vector{OrbitDataMessage}
    @test length(odm) == 1

    omm = first(odm)

    # == Header Fields =====================================================================
    @test omm.version == v"3.0"
    @test omm.header.comments == ["GENERATED VIA SPACE-TRACK.ORG API"]
    @test omm.header.classification === nothing
    @test omm.header.creation_date == NanoDate("2025-12-30T23:36:37")
    @test omm.header.originator == "18 SPCS"
    @test omm.header.message_id === nothing

    # == Metadata Fields ===================================================================
    @test isempty(omm.metadata.comments)
    @test omm.metadata.object_name == "AMAZONIA 1"
    @test omm.metadata.object_id == "2021-015A"
    @test omm.metadata.center_name == "EARTH"
    @test omm.metadata.ref_frame == "TEME"
    @test omm.metadata.ref_frame_epoch === nothing
    @test omm.metadata.time_system == "UTC"
    @test omm.metadata.mean_element_theory == "SGP4"

    # == Data Fields - Mean Keplerian Elements =============================================
    @test isempty(omm.data.comments)
    @test isempty(omm.data.mean_elements_comments)
    @test omm.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    @test omm.data.semi_major_axis === nothing
    @test omm.data.mean_motion ≈ 14.40772474 atol = 1e-6
    @test omm.data.eccentricity ≈ 0.00011240 atol = 1e-8
    @test omm.data.inclination ≈ 98.3721 atol = 1e-4
    @test omm.data.raan ≈ 75.0877 atol = 1e-4
    @test omm.data.arg_of_pericenter ≈ 97.3772 atol = 1e-4
    @test omm.data.mean_anomaly ≈ 262.7545 atol = 1e-4
    @test omm.data.GM === nothing

    # == Data Fields - Spacecraft Data ====================================================
    @test isempty(omm.data.spacecraft_parameters_comments)
    @test omm.data.mass === nothing
    @test omm.data.solar_rad_area === nothing
    @test omm.data.solar_rad_coeff === nothing
    @test omm.data.drag_area === nothing
    @test omm.data.drag_coeff === nothing

    # == Data Fields - TLE Related Parameters ==============================================
    @test isempty(omm.data.tle_parameters_comments)
    @test omm.data.ephemeris_type == 0
    @test omm.data.classification_type == 'U'
    @test omm.data.norad_cat_id == 47699
    @test omm.data.element_set_number == 999
    @test omm.data.rev_at_epoch == 25439
    @test omm.data.bstar ≈ 0.00015330000000 atol = 1e-12
    @test omm.data.mean_motion_dot ≈ 0.00000447 atol = 1e-9
    @test omm.data.mean_motion_ddot ≈ 0.0 atol = 1e-13

    # == Data Fields - User-Defined Parameters ============================================
    @test length(omm.data.user_defined_parameters) == 12

    # Check some specific user-defined parameters
    user_params = Dict(omm.data.user_defined_parameters)

    @test user_params["SEMIMAJOR_AXIS"] == "7134.084"
    @test user_params["PERIOD"] == "99.946"
    @test user_params["APOAPSIS"] == "756.751"
    @test user_params["PERIAPSIS"] == "755.147"
    @test user_params["OBJECT_TYPE"] == "PAYLOAD"
    @test user_params["RCS_SIZE"] == "LARGE"
    @test user_params["COUNTRY_CODE"] == "BRAZ"
    @test user_params["LAUNCH_DATE"] == "2021-02-28"
    @test user_params["SITE"] == "SRI"
    @test user_params["DECAY_DATE"] == ""
    @test user_params["FILE"] == "4946249"
    @test user_params["GP_ID"] == "307230979"
end
