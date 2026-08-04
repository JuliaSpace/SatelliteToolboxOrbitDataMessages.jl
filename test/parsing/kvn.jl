## Description #############################################################################
#
# KVN parsing tests.
#
############################################################################################

"""
    _minimal_omm_kvn(; object_name::String = "AMAZONIA 1", epoch::String = "2025-12-30T18:12:04.533984") -> String

Build a minimal valid OMM KVN string.
"""
function _minimal_omm_kvn(;
    object_name::String = "AMAZONIA 1", epoch::String = "2025-12-30T18:12:04.533984"
)
    return """
    CCSDS_OMM_VERS = 3.0
    CREATION_DATE = 2025-12-30T23:36:37
    ORIGINATOR = 18 SPCS
    OBJECT_NAME = $object_name
    OBJECT_ID = 2021-015A
    CENTER_NAME = EARTH
    REF_FRAME = TEME
    TIME_SYSTEM = UTC
    MEAN_ELEMENT_THEORY = SGP4
    EPOCH = $epoch
    MEAN_MOTION = 14.40772474
    ECCENTRICITY = 0.00011240
    INCLINATION = 98.3721
    RA_OF_ASC_NODE = 75.0877
    ARG_OF_PERICENTER = 97.3772
    MEAN_ANOMALY = 262.7545
    """
end

@testset "KVN Parsing" verbose = true begin
    kvn = _minimal_omm_kvn()

    @testset "parse_omm on Single OMM" begin
        omm = parse_omm(kvn; file_type = :kvn)
        @test omm isa OrbitMeanElementsMessage
        @test omm.metadata.object_name == "AMAZONIA 1"
        @test omm.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    end

    @testset "parse_omms on Single OMM" begin
        omms = parse_omms(kvn; file_type = :kvn)
        @test length(omms) == 1
        @test omms[1].metadata.object_name == "AMAZONIA 1"
    end

    @testset "parse_omms on Two OMMs" begin
        kvn_2 = _minimal_omm_kvn(; object_name = "SAT 2")
        omms  = parse_omms(kvn * kvn_2; file_type = :kvn)
        @test length(omms) == 2
        @test omms[1].metadata.object_name == "AMAZONIA 1"
        @test omms[2].metadata.object_name == "SAT 2"
    end

    @testset "parse_omm on Two OMMs Returns the First" begin
        kvn_2 = _minimal_omm_kvn(; object_name = "SAT 2")
        omm   = parse_omm(kvn * kvn_2; file_type = :kvn)
        @test omm isa OrbitMeanElementsMessage
        @test omm.metadata.object_name == "AMAZONIA 1"
    end

    @testset "Content Before the First OMM Is Ignored" begin
        omms = parse_omms("\n\nCOMMENT Prologue\n" * kvn; file_type = :kvn)
        @test length(omms) == 1
        @test omms[1].metadata.object_name == "AMAZONIA 1"
    end

    @testset "Input Without Trailing Newline" begin
        omms = parse_omms(rstrip(kvn); file_type = :kvn)
        @test length(omms) == 1
    end

    @testset "SubString Input" begin
        @test parse_omm(SubString(kvn); file_type = :kvn) isa OrbitMeanElementsMessage
        @test length(parse_omms(SubString(kvn); file_type = :kvn)) == 1
    end

    @testset "Empty Input" begin
        @test isempty(parse_omms(""; file_type = :kvn))
    end

    @testset "Comments" begin
        kvn_with_comments = """
        CCSDS_OMM_VERS = 3.0
        COMMENT Header comment 1
        COMMENT Header comment 2
        CREATION_DATE = 2025-12-30T23:36:37
        ORIGINATOR = 18 SPCS
        COMMENT Metadata comment
        OBJECT_NAME = AMAZONIA 1
        OBJECT_ID = 2021-015A
        CENTER_NAME = EARTH
        REF_FRAME = TEME
        TIME_SYSTEM = UTC
        MEAN_ELEMENT_THEORY = SGP4
        COMMENT Mean elements comment
        EPOCH = 2025-12-30T18:12:04.533984
        MEAN_MOTION = 14.40772474
        ECCENTRICITY = 0.00011240
        INCLINATION = 98.3721
        RA_OF_ASC_NODE = 75.0877
        ARG_OF_PERICENTER = 97.3772
        MEAN_ANOMALY = 262.7545
        COMMENT Spacecraft comment
        MASS = 640.0
        COMMENT TLE comment
        BSTAR = 0.0001
        MEAN_MOTION_DOT = 0.0
        MEAN_MOTION_DDOT = 0.0
        COMMENT Trailing comment
        """

        omm = parse_omm(kvn_with_comments; file_type = :kvn)

        @test omm.header.comments == ["Header comment 1", "Header comment 2"]
        @test omm.metadata.comments == ["Metadata comment"]
        @test omm.data.mean_elements_comments == ["Mean elements comment"]
        @test omm.data.spacecraft_parameters_comments == ["Spacecraft comment"]
        @test omm.data.tle_parameters_comments == ["TLE comment", "Trailing comment"]
    end

    @testset "Automatic File Type Detection" begin
        @test parse_omm(kvn) isa OrbitMeanElementsMessage
        @test length(parse_omms(kvn)) == 1
    end
end
