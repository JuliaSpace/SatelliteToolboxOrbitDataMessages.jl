## Description #############################################################################
#
# Spacetrack fetcher offline tests.
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

@testset "Spacetrack Fetcher (Offline)" verbose = true begin
    # == Invalid space_data ================================================================

    @testset "Invalid space_data" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            space_data = :foo,
            satellite_name = "TEST",
        )
    end

    # == Bad Interval (start >= end) =======================================================

    @testset "Bad Interval" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            interval = (DateTime(2024, 6, 20), DateTime(2024, 6, 19)),
            satellite_name = "TEST",
        )
    end

    # == Bad order_by Direction ============================================================

    @testset "Bad order_by" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            order_by = ["EPOCH" => :sideways],
            satellite_name = "TEST",
        )
    end

    # == query_limits = 0 ==================================================================

    @testset "query_limits = 0" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            query_limits = 0,
            satellite_name = "TEST",
        )
    end

    # == query_limits = 5:3 (Empty Range) ==================================================

    @testset "Empty query_limits Range" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(
            fetcher;
            query_limits = 5:3,
            satellite_name = "TEST",
        )
    end

    # == _spacetrack__is_cookie_valid(nothing) =============================================

    @testset "Cookie Validity (nothing)" begin
        @test !SatelliteToolboxOrbitDataMessages._spacetrack__is_cookie_valid(nothing)
    end

    # == Expired Cookie ====================================================================

    @testset "Expired Cookie" begin
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

    # == Valid Cookie ======================================================================

    @testset "Valid Cookie" begin
        cookiejar = _valid_spacetrack_cookiejar()
        @test SatelliteToolboxOrbitDataMessages._spacetrack__is_cookie_valid(cookiejar)
    end
end

@testset "Spacetrack Fetcher Exceptions (Offline)" verbose = true begin
    # == Expired Cookie Throws =============================================================

    @testset "Expired Cookie Throws" begin
        cookiejar = HTTP.CookieJar()
        host = "www.space-track.org"
        cookie_path = host * ";/;chocolatechip"
        cookiejar.entries[host] = Dict{String, HTTP.Cookie}()
        cookiejar.entries[host][cookie_path] = HTTP.Cookie(;
            name    = "chocolatechip",
            value   = "test",
            expires = Dates.now(Dates.UTC) - Dates.Hour(1),
        )

        fetcher = SpacetrackOmmFetcher("test", cookiejar)

        @test_throws OdmLoginError fetch_omms(fetcher; satellite_name = "TEST")
    end

    # == Empty Query Throws ================================================================

    @testset "Empty Query Throws" begin
        fetcher = SpacetrackOmmFetcher("test", _valid_spacetrack_cookiejar())

        @test_throws ArgumentError fetch_omms(fetcher)
    end

    # == Exception Display =================================================================

    @testset "Exception Display" begin
        login_error = OdmLoginError("login failed")
        @test sprint(showerror, login_error) == "OdmLoginError: login failed"

        fetch_error = OdmFetchError("request failed")
        @test sprint(showerror, fetch_error) == "OdmFetchError: request failed"

        fetch_error = OdmFetchError(
            "request failed";
            url = "https://example.com",
            status = 500,
        )
        @test sprint(showerror, fetch_error) ==
            "OdmFetchError: request failed (HTTP status: 500)\nURL: https://example.com"
    end
end
