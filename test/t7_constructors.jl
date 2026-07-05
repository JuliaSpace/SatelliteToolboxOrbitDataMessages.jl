## Description #############################################################################
#
# T7 — OrbitMeanElementsMessage constructor tests.
#
############################################################################################

@testset "T7: Constructors" verbose = true begin
    # Common required fields.
    creation_date  = NanoDate("2025-12-30T23:36:37")
    epoch          = NanoDate("2025-12-30T18:12:04.533984")

    # == T7.1: Full keyword constructor -> v3.0 ==========================================

    @testset "T7.1: Full keyword constructor" begin
        omm = OrbitMeanElementsMessage(;
            header_comment   = "Test header",
            classification   = "UNCLASSIFIED",
            creation_date    = creation_date,
            originator       = "TEST",
            message_id       = "MSG-001",
            object_name      = "TEST SAT",
            object_id        = "2025-001A",
            center_name      = "EARTH",
            ref_frame        = "TEME",
            time_system      = "UTC",
            mean_element_theory = "SGP4",
            epoch            = epoch,
            semi_major_axis  = 7000.0,
            mean_motion      = 15.0,
            eccentricity     = 0.001,
            inclination      = 45.0,
            raan             = 100.0,
            arg_of_pericenter = 50.0,
            mean_anomaly     = 200.0,
            GM               = 398600.4418,
            mass             = 100.0,
            bstar            = 1e-4,
            norad_cat_id     = 12345,
        )

        @test omm.version == v"3.0"
        @test omm.header.comment == "Test header"
        @test omm.header.classification == "UNCLASSIFIED"
        @test omm.header.message_id == "MSG-001"
        @test omm.body.segment.data.mass == 100.0
        @test omm.body.segment.data.bstar ≈ 1e-4
        @test omm.body.segment.data.norad_cat_id == 12345
    end

    # == T7.2: Minimal keyword constructor ===============================================

    @testset "T7.2: Minimal keyword constructor" begin
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

        @test omm.version == v"3.0"
        @test omm.header.comment === nothing
        @test omm.header.classification === nothing
        @test omm.header.message_id === nothing
        @test omm.body.segment.data.semi_major_axis === nothing
        @test omm.body.segment.data.mean_motion === nothing
        @test omm.body.segment.data.GM === nothing
        @test omm.body.segment.data.mass === nothing
        @test omm.body.segment.data.bstar === nothing
        @test omm.body.segment.data.user_defined_parameters === nothing
    end

    # == T7.3: Reconstruction override one field =========================================

    @testset "T7.3: Reconstruction override one field" begin
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

        omm2 = OrbitMeanElementsMessage(omm; object_name = "NEW NAME")

        @test omm2.body.segment.metadata.object_name == "NEW NAME"
        # All other fields preserved.
        @test omm2.header.originator == omm.header.originator
        @test omm2.body.segment.metadata.object_id == omm.body.segment.metadata.object_id
        @test omm2.body.segment.data.epoch == omm.body.segment.data.epoch
        @test omm2.body.segment.data.eccentricity == omm.body.segment.data.eccentricity
    end

    # == T7.4: Reconstruction override multiple fields ====================================

    @testset "T7.4: Reconstruction override multiple fields" begin
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

        omm2 = OrbitMeanElementsMessage(omm;
            object_name = "NEW NAME",
            originator  = "NEW ORG",
            inclination = 50.0,
        )

        @test omm2.body.segment.metadata.object_name == "NEW NAME"
        @test omm2.header.originator == "NEW ORG"
        @test omm2.body.segment.data.inclination == 50.0
        # Unchanged fields.
        @test omm2.body.segment.metadata.object_id == omm.body.segment.metadata.object_id
        @test omm2.body.segment.data.raan == omm.body.segment.data.raan
    end
end
