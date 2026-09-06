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
        omm = parse_omm(kvn; format = :kvn)
        @test omm isa OrbitMeanElementsMessage
        @test omm.metadata.object_name == "AMAZONIA 1"
        @test omm.data.epoch == NanoDate("2025-12-30T18:12:04.533984")
    end

    @testset "parse_omms on Single OMM" begin
        omms = parse_omms(kvn; format = :kvn)
        @test length(omms) == 1
        @test omms[1].metadata.object_name == "AMAZONIA 1"
    end

    @testset "parse_omms on Two OMMs" begin
        kvn_2 = _minimal_omm_kvn(; object_name = "SAT 2")
        omms  = parse_omms(kvn * kvn_2; format = :kvn)
        @test length(omms) == 2
        @test omms[1].metadata.object_name == "AMAZONIA 1"
        @test omms[2].metadata.object_name == "SAT 2"
    end

    @testset "parse_omm on Two OMMs Returns the First" begin
        kvn_2 = _minimal_omm_kvn(; object_name = "SAT 2")
        omm   = parse_omm(kvn * kvn_2; format = :kvn)
        @test omm isa OrbitMeanElementsMessage
        @test omm.metadata.object_name == "AMAZONIA 1"
    end

    @testset "Content Before the First OMM Is Ignored" begin
        omms = parse_omms("\n\nCOMMENT Prologue\n" * kvn; format = :kvn)
        @test length(omms) == 1
        @test omms[1].metadata.object_name == "AMAZONIA 1"
    end

    @testset "Input Without Trailing Newline" begin
        omms = parse_omms(rstrip(kvn); format = :kvn)
        @test length(omms) == 1
    end

    @testset "SubString Input" begin
        @test parse_omm(SubString(kvn); format = :kvn) isa OrbitMeanElementsMessage
        @test length(parse_omms(SubString(kvn); format = :kvn)) == 1
    end

    @testset "Empty Input" begin
        @test isempty(parse_omms(""; format = :kvn))
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

        omm = parse_omm(kvn_with_comments; format = :kvn)

        @test omm.header.comments == ["Header comment 1", "Header comment 2"]
        @test omm.metadata.comments == ["Metadata comment"]
        @test omm.data.mean_elements_comments == ["Mean elements comment"]
        @test omm.data.spacecraft_parameters_comments == ["Spacecraft comment"]
        @test omm.data.tle_parameters_comments == ["TLE comment", "Trailing comment"]
    end

    @testset "Automatic Format Detection" begin
        @test parse_omm(kvn) isa OrbitMeanElementsMessage
        @test length(parse_omms(kvn)) == 1
        @test length(parse_odm(kvn)) == 1
    end

    @testset "parse_odm and read_odm" begin
        kvn_2 = _minimal_omm_kvn(; object_name = "SAT 2")

        for odms in (parse_odm(kvn * kvn_2; format = :kvn), parse_odm(kvn * kvn_2))
            @test odms isa Vector{OrbitDataMessage}
            @test length(odms) == 2
            @test odms[1] == parse_omm(kvn)
            @test odms[2].metadata.object_name == "SAT 2"
        end

        @test isempty(parse_odm(""; format = :kvn))

        mktempdir() do dir
            file = joinpath(dir, "omm.kvn")
            write(file, kvn)
            @test read_odm(file) == parse_odm(kvn)
            @test read_odm(file; format = :kvn) == parse_odm(kvn)
            @test open(read_odm, file, "r") == parse_odm(kvn)
        end

        @test_throws ArgumentError parse_odm(kvn; format = :json)
    end

    @testset "Byte-Order Mark Handling" begin
        @test parse_omm("\ufeff" * _fixture_omm_xml()) isa OrbitMeanElementsMessage
        @test parse_omm("\ufeff" * kvn) isa OrbitMeanElementsMessage
        @test length(parse_omms("\ufeff" * kvn)) == 1
    end

    @testset "Chunk Detection Requires Exact Keyword" begin
        # A keyword merely starting with `CCSDS_OMM_VERS` must not start a new message.
        omms = parse_omms("CCSDS_OMM_VERSION = 9.9\n" * kvn; format = :kvn)
        @test length(omms) == 1
        @test omms[1].metadata.object_name == "AMAZONIA 1"
    end

    @testset "Bracketed Tokens in String Values" begin
        # A trailing bracketed token in a string value is part of the value, not a unit.
        kvn_brackets = replace(
            kvn, "OBJECT_NAME = AMAZONIA 1" => "OBJECT_NAME = ISS (ZARYA) [A]"
        )
        omm = parse_omm(kvn_brackets; format = :kvn)
        @test omm.metadata.object_name == "ISS (ZARYA) [A]"
    end

    @testset "Units in Numeric Values" begin
        kvn_units = replace(
            kvn,
            "MEAN_MOTION = 14.40772474" => "MEAN_MOTION = 14.40772474 [rev/day]",
            "INCLINATION = 98.3721"     => "INCLINATION = 98.3721 [deg]",
        )
        omm = parse_omm(kvn_units; format = :kvn)
        @test omm.data.mean_motion == 14.40772474
        @test omm.data.inclination == 98.3721
    end

    @testset "User-Defined Values With Brackets" begin
        kvn_udp = kvn * "USER_DEFINED_RANGES = [1, 2]\n"
        omm     = parse_omm(kvn_udp; format = :kvn)
        @test omm.data.user_defined_parameters == ["RANGES" => "[1, 2]"]
    end

    @testset "Comment Keyword Boundary" begin
        # A keyword merely starting with `COMMENT` must not be absorbed as a comment.
        @test_throws OdmParseError parse_omm(
            "CCSDS_OMM_VERS = 3.0\nCOMMENTARY IS FUN\n"; format = :kvn
        )

        # A bare `COMMENT` line is a valid empty comment, and any indentation beyond the
        # single separating space is preserved.
        kvn_comments = "CCSDS_OMM_VERS = 3.0\nCOMMENT\nCOMMENT   indented\n" * join(
            split(kvn, '\n')[2:end], '\n'
        )
        omm = parse_omm(kvn_comments; format = :kvn)
        @test omm.header.comments == ["", "  indented"]
    end
end
