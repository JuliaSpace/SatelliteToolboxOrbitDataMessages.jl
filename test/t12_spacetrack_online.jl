## Description #############################################################################
#
# T12 — Spacetrack fetcher online tests (gated behind HAS_SPACETRACK env var).
#
############################################################################################

@testset "T12: Spacetrack fetcher (online)" verbose = true begin
    if !haskey(ENV, "HAS_SPACETRACK")
        @test_skip "Set HAS_SPACETRACK=1 to run online Spacetrack tests"
        return
    end

    # == T12.1: Bad credentials ==========================================================

    @testset "T12.1: Bad credentials" begin
        f = create_omm_fetcher(
            SpacetrackOmmFetcher;
            username = "bad_user_$(randstring(8))",
            password = "bad_password",
        )

        @test isnothing(f)
    end

    # == T12.2: Fetch by satellite name ==================================================

    @testset "T12.2: Fetch AMAZONIA 1" begin
        f = create_omm_fetcher(SpacetrackOmmFetcher)

        if !isnothing(f)
            result = fetch_omms(f; satellite_name = "AMAZONIA 1")
            @test !isnothing(result)
            if !isnothing(result) && !isempty(result)
                omm = first(result)
                @test omm isa OrbitMeanElementsMessage
                @test omm.body.segment.metadata.object_name == "AMAZONIA 1"
            end
        else
            @test_skip "Could not login to Space-Track"
        end
    end

    # == T12.3: Fetch by satellite_number + interval ====================================

    @testset "T12.3: Fetch by number + interval" begin
        f = create_omm_fetcher(SpacetrackOmmFetcher)

        if !isnothing(f)
            result = fetch_omms(
                f;
                satellite_number = 47699,
                interval = (Date(2024, 1, 1), Date(2024, 12, 31)),
            )
            @test !isnothing(result)
            if !isnothing(result)
                @test !isempty(result)
                for omm in result
                    @test omm.body.segment.data.norad_cat_id == 47699
                end
            end
        else
            @test_skip "Could not login to Space-Track"
        end
    end

    # == T12.4: Complex predicates =======================================================

    @testset "T12.4: Complex predicates" begin
        f = create_omm_fetcher(SpacetrackOmmFetcher)

        if !isnothing(f)
            result = fetch_omms(
                f;
                predicates = [
                    "NORAD_CAT_ID" => "40000--40100",
                    "MEAN_MOTION"  => "<14.9",
                ],
                query_limits = 5,
            )
            @test !isnothing(result)
            if !isnothing(result) && !isempty(result)
                for omm in result
                    @test 40000 <= omm.body.segment.data.norad_cat_id <= 40100
                end
            end
        else
            @test_skip "Could not login to Space-Track"
        end
    end
end
