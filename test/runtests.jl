using Test

using Dates
using NanoDates
using SatelliteToolboxOrbitDataMessages

include("_helpers.jl")

@testset "SatelliteToolboxOrbitDataMessages" begin
    @testset "Parsing ODMs" verbose = true begin
        include("omm_parsing.jl")
        include("odm_parsing.jl")
        include("t1_round_trip.jl")
        include("t2_ndm_container.jl")
        include("t3_parsing_errors.jl")
        include("t4_case_insensitivity.jl")
        include("t5_optional_fields.jl")
        include("t6_user_defined_params.jl")
    end

    @testset "Constructors" verbose = true begin
        include("t7_constructors.jl")
    end

    @testset "Display" verbose = true begin
        include("omm_display.jl")
        include("t8_display_variations.jl")
    end

    @testset "Write" verbose = true begin
        include("t9_write_structure.jl")
    end

    @testset "Regression" verbose = true begin
        include("t14_regression.jl")
    end
end
