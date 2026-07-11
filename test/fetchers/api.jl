## Description #############################################################################
#
# Fetcher API tests.
#
############################################################################################

"""
    UnregisteredOmmFetcher

OMM fetcher used to test the fallback API methods.
"""
struct UnregisteredOmmFetcher <: SatelliteToolboxOrbitDataMessages.AbstractOmmFetcher end

@testset "Fetcher API" verbose = true begin
    # == Undefined Constructor =============================================================

    @testset "Undefined Constructor" begin
        exception = try
            create_omm_fetcher(UnregisteredOmmFetcher, "argument"; option = true)
            nothing
        catch exception
            exception
        end

        @test exception isa ArgumentError
        @test exception.msg ==
            "The OMM fetcher UnregisteredOmmFetcher is not registered."
    end

    # == Undefined Fetch Method ============================================================

    @testset "Undefined Fetch Method" begin
        exception = try
            fetch_omms(UnregisteredOmmFetcher(); option = true)
            nothing
        catch exception
            exception
        end

        @test exception isa ArgumentError
        @test exception.msg ==
            "The OMM fetcher UnregisteredOmmFetcher is not registered."
    end
end
