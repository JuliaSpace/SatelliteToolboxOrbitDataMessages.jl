## Description #############################################################################
#
# Test the parsing of Orbit Data Messages (ODM).
#
############################################################################################

@testset "Parse ODM From File" verbose = true begin
    odm = read_odm(joinpath(@__DIR__, "2025-12-30-Amazonia_1.xml"))

    @test odm isa Vector{OrbitDataMessage}
    @test length(odm) == 1

    omm = first(odm)

    # == Header Fields =====================================================================
    @test omm.version               == v"3.0"
    @test omm.header.comment        == "GENERATED VIA SPACE-TRACK.ORG API"
    @test omm.header.classification === nothing
    @test omm.header.creation_date  == NanoDate("2025-12-30T23:36:37")
    @test omm.header.originator     == "18 SPCS"
    @test omm.header.message_id     === nothing

    # == Metadata Fields ===================================================================
    @test omm.body.segment.metadata.comment             === nothing
    @test omm.body.segment.metadata.object_name         == "AMAZONIA 1"
    @test omm.body.segment.metadata.object_id           == "2021-015A"
    @test omm.body.segment.metadata.center_name         == "EARTH"
    @test omm.body.segment.metadata.ref_frame           == "TEME"
    @test omm.body.segment.metadata.ref_frame_epoch     === nothing
    @test omm.body.segment.metadata.time_system         == "UTC"
    @test omm.body.segment.metadata.mean_element_theory == "SGP4"

    # == Data Fields - Mean Keplerian Elements =============================================
    @test omm.body.segment.data.data_comment      === nothing
    @test omm.body.segment.data.epoch             ==  NanoDate("2025-12-30T18:12:04.533984")
    @test omm.body.segment.data.semi_major_axis   === nothing
    @test omm.body.segment.data.mean_motion       ≈   14.40772474 atol = 1e-6
    @test omm.body.segment.data.eccentricity      ≈   0.00011240  atol = 1e-8
    @test omm.body.segment.data.inclination       ≈   98.3721     atol = 1e-4
    @test omm.body.segment.data.raan              ≈   75.0877     atol = 1e-4
    @test omm.body.segment.data.arg_of_pericenter ≈   97.3772     atol = 1e-4
    @test omm.body.segment.data.mean_anomaly      ≈   262.7545    atol = 1e-4
    @test omm.body.segment.data.GM                === nothing

    # == Data Fields - Spacecraft Data ====================================================
    @test omm.body.segment.data.spacecraft_data_comment === nothing
    @test omm.body.segment.data.mass                    === nothing
    @test omm.body.segment.data.solar_rad_area          === nothing
    @test omm.body.segment.data.solar_rad_coeff         === nothing
    @test omm.body.segment.data.drag_area               === nothing
    @test omm.body.segment.data.drag_coeff              === nothing

    # == Data Fields - TLE Related Parameters ==============================================
    @test omm.body.segment.data.tle_parameters_comment === nothing
    @test omm.body.segment.data.ephemeris_type         ==  0
    @test omm.body.segment.data.classification_type    ==  'U'
    @test omm.body.segment.data.norad_cat_id           ==  47699
    @test omm.body.segment.data.element_set_number     ==  999
    @test omm.body.segment.data.rev_at_epoch           ==  25439
    @test omm.body.segment.data.bstar                  ≈   0.00015330000000 atol = 1e-12
    @test omm.body.segment.data.mean_motion_dot        ≈   0.00000447       atol = 1e-9
    @test omm.body.segment.data.mean_motion_ddot       ≈   0.0              atol = 1e-13

    # == Data Fields - User-Defined Parameters ============================================
    @test omm.body.segment.data.user_defined_parameters         !== nothing
    @test length(omm.body.segment.data.user_defined_parameters) ==  12

    # Check some specific user-defined parameters
    user_params = Dict(omm.body.segment.data.user_defined_parameters)

    @test user_params["SEMIMAJOR_AXIS"] == "7134.084"
    @test user_params["PERIOD"]         == "99.946"
    @test user_params["APOAPSIS"]       == "756.751"
    @test user_params["PERIAPSIS"]      == "755.147"
    @test user_params["OBJECT_TYPE"]    == "PAYLOAD"
    @test user_params["RCS_SIZE"]       == "LARGE"
    @test user_params["COUNTRY_CODE"]   == "BRAZ"
    @test user_params["LAUNCH_DATE"]    == "2021-02-28"
    @test user_params["SITE"]           == "SRI"
    @test user_params["DECAY_DATE"]     == ""
    @test user_params["FILE"]           == "4946249"
    @test user_params["GP_ID"]          == "307230979"
end
