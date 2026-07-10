using Test

using Dates
using HTTP
using NanoDates
using Random
using SatelliteToolboxOrbitDataMessages
using SatelliteToolboxTle

include("helpers.jl")

@testset "SatelliteToolboxOrbitDataMessages" verbose = true begin
    @testset "Parsing ODMs" verbose = true begin
        include("omm_parsing.jl")
        include("odm_parsing.jl")
        include("round_trip.jl")
        include("ndm_container.jl")
        include("parsing_errors.jl")
        include("case_insensitivity.jl")
        include("optional_fields.jl")
        include("user_defined_params.jl")
        include("covariance_matrix.jl")
        include("date_formats.jl")
    end

    @testset "Constructors" verbose = true begin
        include("constructors.jl")
    end

    @testset "Display" verbose = true begin
        include("display.jl")
    end

    @testset "Write" verbose = true begin
        include("write.jl")
    end

    @testset "Fetchers" verbose = true begin
        include("fetcher/celestrak.jl")
        include("fetcher/spacetrack_offline.jl")
        include("fetcher/spacetrack_online.jl")
    end

    @testset "TLE Extension" verbose = true begin
        include("tle_extension.jl")
    end

    @testset "Issues" verbose = true begin
        include("issues.jl")
    end
end
