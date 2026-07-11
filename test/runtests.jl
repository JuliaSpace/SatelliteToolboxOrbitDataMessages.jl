using Test

using Dates
using HTTP
using NanoDates
using Random
using SatelliteToolboxOrbitDataMessages
using SatelliteToolboxTle
using XML

include("helpers.jl")

@testset "SatelliteToolboxOrbitDataMessages" verbose = true begin
    @testset "Parsing ODMs" verbose = true begin
        include("parsing/omm.jl")
        include("parsing/odm.jl")
        include("parsing/ndm.jl")
        include("parsing/errors.jl")
        include("parsing/case_insensitivity.jl")
        include("parsing/optional_fields.jl")
        include("parsing/user_defined_parameters.jl")
        include("parsing/covariance_matrix.jl")
        include("parsing/date_formats.jl")
    end

    @testset "Constructors" verbose = true begin
        include("interface/constructors.jl")
    end

    @testset "Equality" verbose = true begin
        include("interface/equality.jl")
    end

    @testset "Display" verbose = true begin
        include("interface/display.jl")
    end

    @testset "Serialization" verbose = true begin
        include("serialization/write.jl")
        include("serialization/round_trip.jl")
    end

    @testset "Fetchers" verbose = true begin
        include("fetchers/api.jl")
        include("fetchers/celestrak.jl")
        include("fetchers/spacetrack_offline.jl")
        include("fetchers/spacetrack_online.jl")
    end

    @testset "TLE Extension" verbose = true begin
        include("extensions/tle.jl")
    end

    @testset "Issues" verbose = true begin
        include("regressions/issues.jl")
    end
end
