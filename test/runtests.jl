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

    @testset "Display" verbose = true begin
        include("omm_display.jl")
    end
end
