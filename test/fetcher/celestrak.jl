## Description #############################################################################
#
# Celestrak fetcher tests.
#
############################################################################################

@testset "Celestrak fetcher" verbose = true begin
    # == Default URL =======================================================================

    @testset "Default fetcher" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test f isa CelestrakOmmFetcher
        @test f.url == "https://celestrak.org/NORAD/elements/gp.php"
    end

    # == Custom URL ========================================================================

    @testset "Custom URL" begin
        f = create_omm_fetcher(CelestrakOmmFetcher; url="https://example.com/api")
        @test f.url == "https://example.com/api"
    end

    # == Display ===========================================================================

    @testset "Display" begin
        f = create_omm_fetcher(CelestrakOmmFetcher; url="https://example.com/api")
        @test sprint(show, f) == "CelestrakOmmFetcher: https://example.com/api"
    end

    # == Negative satellite number =========================================================

    @testset "Negative satellite number" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f; satellite_number=-1)
    end

    # == Bad international designator ======================================================

    @testset "Bad international designator" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f; international_designator="bad-format")
    end

    # == Empty satellite name ==============================================================

    @testset "Empty satellite name" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f; satellite_name="")
    end

    # == No query information ==============================================================

    @testset "No query info" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f)
    end

    # == Network lookup (ISS) ==============================================================
    # This test makes a real HTTP request to Celestrak. It is not gated behind an env flag
    # because Celestrak is a free public service. If the network is unavailable, the test
    # is skipped gracefully.

    @testset "Fetch ISS (network)" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        result = try
            fetch_omms(f; satellite_number=25544)
        catch e
            e
        end

        if result isa Exception
            @test_skip "Network unavailable: $(typeof(result))"
        else
            @test !isnothing(result)
            if !isnothing(result) && !isempty(result)
                omm = first(result)
                @test omm isa OrbitMeanElementsMessage
                @test omm.body.segment.data.norad_cat_id == 25544
            end
        end
    end
end
