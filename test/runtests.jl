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
    end

    @testset "Display" verbose = true begin
        include("omm_display.jl")
    end
end
