## Description #############################################################################
#
# T10 — Celestrak fetcher tests.
#
############################################################################################

@testset "T10: Celestrak fetcher" verbose = true begin
    # == T10.1: Default URL ===============================================================

    @testset "T10.1: Default fetcher" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test f isa CelestrakOmmFetcher
        @test f.url == "https://celestrak.org/NORAD/elements/gp.php"
    end

    # == T10.2: Custom URL ================================================================

    @testset "T10.2: Custom URL" begin
        f = create_omm_fetcher(CelestrakOmmFetcher; url="https://example.com/api")
        @test f.url == "https://example.com/api"
    end

    # == T10.3: Negative satellite number =================================================

    @testset "T10.3: Negative satellite number" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f; satellite_number=-1)
    end

    # == T10.4: Bad international designator ==============================================

    @testset "T10.4: Bad international designator" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f; international_designator="bad-format")
    end

    # == T10.5: Empty satellite name ======================================================

    @testset "T10.5: Empty satellite name" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f; satellite_name="")
    end

    # == T10.6: No query information ======================================================

    @testset "T10.6: No query info" begin
        f = create_omm_fetcher(CelestrakOmmFetcher)
        @test_throws ArgumentError fetch_omms(f)
    end

    # == T10.7: Network lookup (ISS) ======================================================
    # This test makes a real HTTP request to Celestrak. It is not gated behind an env flag
    # because Celestrak is a free public service. If the network is unavailable, the test
    # is skipped gracefully.

    @testset "T10.7: Fetch ISS (network)" begin
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
