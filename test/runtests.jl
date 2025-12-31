using Test

using NanoDates
using SatelliteToolboxOrbitDataMessages

@testset "Parsing ODMs" verbose = true begin
    include("omm_parsing.jl")
    include("odm_parsing.jl")
end

@testset "Display" verbose = true begin
    include("omm_display.jl")
end