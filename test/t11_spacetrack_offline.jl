## Description #############################################################################
#
# T11 — Spacetrack fetcher offline tests.
#
############################################################################################

# Build a cookiejar with a valid (future-expiring) cookie so that fetch_omms reaches the
# argument-validation logic instead of short-circuiting on the cookie check.
function _valid_spacetrack_cookiejar()
    cookiejar = HTTP.CookieJar()
    host = "www.space-track.org"
    cookie_path = host * ";/;chocolatechip"
    cookiejar.entries[host] = Dict{String, HTTP.Cookie}()
    cookiejar.entries[host][cookie_path] = HTTP.Cookie(;
        name    = "chocolatechip",
        value   = "test",
        expires = Dates.now(Dates.UTC) + Dates.Hour(4),
    )

    return cookiejar
end

@testset "T11: Spacetrack fetcher (offline)" verbose = true begin
    # == T11.2: Invalid space_data ========================================================

    @testset "T11.2: Invalid space_data" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            space_data = :foo,
            satellite_name = "TEST",
        )
    end

    # == T11.3: Bad interval (start >= end) ===============================================

    @testset "T11.3: Bad interval" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            interval = (DateTime(2024, 6, 20), DateTime(2024, 6, 19)),
            satellite_name = "TEST",
        )
    end

    # == T11.4: Bad order_by direction ====================================================

    @testset "T11.4: Bad order_by" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            order_by = ["EPOCH" => :sideways],
            satellite_name = "TEST",
        )
    end

    # == T11.5: query_limits = 0 ==========================================================

    @testset "T11.5: query_limits = 0" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            query_limits = 0,
            satellite_name = "TEST",
        )
    end

    # == T11.6: query_limits = 5:3 (empty range) =========================================

    @testset "T11.6: Empty query_limits range" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            query_limits = 5:3,
            satellite_name = "TEST",
        )
    end

    # == T11.9: _spacetrack__is_cookie_valid(nothing) =====================================

    @testset "T11.9: Cookie validity (nothing)" begin
        @test !SatelliteToolboxOrbitDataMessages._spacetrack__is_cookie_valid(nothing)
    end

    # == T11.10: Expired cookie ===========================================================

    @testset "T11.10: Expired cookie" begin
        cookiejar = HTTP.CookieJar()
        host = "www.space-track.org"
        cookie_path = host * ";/;chocolatechip"
        cookiejar.entries[host] = Dict{String, HTTP.Cookie}()
        cookiejar.entries[host][cookie_path] = HTTP.Cookie(;
            name    = "chocolatechip",
            value   = "test",
            expires = Dates.now(Dates.UTC) - Dates.Hour(1),
        )

        @test !SatelliteToolboxOrbitDataMessages._spacetrack__is_cookie_valid(cookiejar)
    end

    # == T11.11: Valid cookie =============================================================

    @testset "T11.11: Valid cookie" begin
        cookiejar = _valid_spacetrack_cookiejar()
        @test SatelliteToolboxOrbitDataMessages._spacetrack__is_cookie_valid(cookiejar)
    end
end
