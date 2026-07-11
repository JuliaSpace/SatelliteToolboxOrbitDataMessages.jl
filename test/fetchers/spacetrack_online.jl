## Description #############################################################################
#
# Spacetrack fetcher online tests (gated behind HAS_SPACETRACK env var).
#
############################################################################################

"""
    _try_create_spacetrack_fetcher() -> Union{Nothing, SpacetrackOmmFetcher}

Create a Space-Track fetcher, returning `nothing` if the login fails.
"""
function _try_create_spacetrack_fetcher()
    try
        return create_omm_fetcher(SpacetrackOmmFetcher)
    catch e
        e isa OdmLoginError && return nothing
        rethrow(e)
    end
end

@testset "Spacetrack Fetcher (Online)" verbose = true begin
    if !haskey(ENV, "HAS_SPACETRACK")
        @test_skip "Set HAS_SPACETRACK=1 to run online Spacetrack tests"
        return
    end

    # == Bad Credentials ===================================================================

    @testset "Bad Credentials" begin
        @test_throws OdmLoginError create_omm_fetcher(
            SpacetrackOmmFetcher;
            username = "bad_user_$(randstring(8))",
            password = "bad_password",
        )
    end

    # == Fetch by Satellite Name ===========================================================

    @testset "Fetch AMAZONIA 1" begin
        f = _try_create_spacetrack_fetcher()

        if !isnothing(f)
            result = fetch_omms(f; satellite_name = "AMAZONIA 1")
            @test result isa Vector{OrbitMeanElementsMessage}
            if !isempty(result)
                omm = first(result)
                @test omm isa OrbitMeanElementsMessage
                @test omm.body.segment.metadata.object_name == "AMAZONIA 1"
            end
        else
            @test_skip "Could not login to Space-Track"
        end
    end

    # == Fetch by satellite_number + Interval ==============================================

    @testset "Fetch by Number + Interval" begin
        f = _try_create_spacetrack_fetcher()

        if !isnothing(f)
            result = fetch_omms(
                f;
                satellite_number = 47699,
                interval = (Date(2024, 1, 1), Date(2024, 12, 31)),
            )
            @test result isa Vector{OrbitMeanElementsMessage}
            @test !isempty(result)
            for omm in result
                @test omm.body.segment.data.norad_cat_id == 47699
            end
        else
            @test_skip "Could not login to Space-Track"
        end
    end

    # == Complex Predicates ================================================================

    @testset "Complex Predicates" begin
        f = _try_create_spacetrack_fetcher()

        if !isnothing(f)
            result = fetch_omms(
                f;
                predicates = [
                    "NORAD_CAT_ID" => "40000--40100",
                    "MEAN_MOTION"  => "<14.9",
                ],
                query_limits = 5,
            )
            @test result isa Vector{OrbitMeanElementsMessage}
            for omm in result
                @test 40000 <= omm.body.segment.data.norad_cat_id <= 40100
            end
        else
            @test_skip "Could not login to Space-Track"
        end
    end
end
