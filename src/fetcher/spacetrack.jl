## Description #############################################################################
#
# Create the Space-Track OMM fetcher.
#
############################################################################################

export SpacetrackOmmFetcher

const _SPACETRACK__HOST        = "www.space-track.org"
const _SPACETRACK__URL         = "https://" * _SPACETRACK__HOST
const _SPACETRACK__LOGIN_URL   = _SPACETRACK__URL * "/ajaxauth/login"
const _SPACETRACK__COOKIE_NAME = "chocolatechip"

struct SpacetrackOmmFetcher <: AbstractOmmFetcher
    username::String
    cookiejar::HTTP.CookieJar
end

############################################################################################
#                                        Julia API                                         #
############################################################################################

function Base.show(io::IO, fetcher::SpacetrackOmmFetcher)
    expires = _spacetrack__cookie_expire_date(fetcher.cookiejar)
    Δt = isnothing(expires) ?
        "Unknown" :
        Dates.canonicalize(Dates.CompoundPeriod(expires - Dates.now()))
    print(io, "SpacetrackOmmFetcher: $(fetcher.username) (Login expires in $Δt)")
end

############################################################################################
#                                        Fetch API                                         #
############################################################################################

"""
    create_omm_fetcher(::Type{SpacetrackTleFetcher}; kwargs...) -> SpacetrackOmmFetcher

Create an Orbit Mean-Elements Message (OMM) fetcher from Spacetrack service.

!!! note

    The Space-Track service is only available to registered users. You can create an
    account for free [here](https://www.space-track.org/auth/createAccount).
    By using this service, you agree to the
    [Space-Track User Agreement](https://www.space-track.org/documentation#/user_agree).

!!! warning

    The Space-Track service has limits on the number of requests that can be made in a given
    time period. This package does not handle these limits, so if you make too many requests
    in a short period of time, you may be temporarily blocked from accessing the service.
    Please refer to the
    [Space-Track API documentation](https://www.space-track.org/documentation#/api) for more
    information.

# Keywords

- `username::String`: Space-Track username. If empty, the user will be prompted to input it.
    (**Default**: "")
- `password::String`: Space-Track password. If empty, the user will be prompted to input it
    if a valid cookie is not found.
    (**Default**: "")
- `force_login::Bool`: If `true`, the user will be prompted to input the password even if a
    valid cookie is found.
    (**Default**: `false`)
"""
function create_omm_fetcher(
    ::Type{SpacetrackOmmFetcher};
    username::String = "",
    password::String = "",
    force_login::Bool = false
)
    # If the username is empty, request the user to input it.
    if isempty(username)
        print("Space-Track username: ")
        username = readline()
    end

    # We will try to load the cookies from the scratch space and check if they are still
    # valid. If not, we will ask for the password and try to login.
    cookiejar = _spacetrack__load_cookiejar(username)

    if !_spacetrack__is_cookie_valid(cookiejar) || force_login
        # If the password is empty, request the user to input it.
        if isempty(password)
            password = Base.getpass("Space-Track password")
            println()
        end

        # Try to login.
        password_str = read(password, String)
        Base.shred!(password)
        success, cookiejar = _spacetrack__login(username, password_str)

        if !success || isnothing(cookiejar)
            @error "Could not login to Space-Track. Please check your credentials."
            return nothing
        end
    else
        @info "A valid login cookie was found. Using it to fetch data."
    end

    return SpacetrackOmmFetcher(username, cookiejar)
end

"""
    fetch_omms(fetcher::SpacetrackOmmFetcher; kwargs...) -> Union{Nothing, Vector{OrbitMeanElementsMessage{T}}}

Fetch Orbit Mean-Elements Messages (OMM) from the Spacetrack using `fetch` with the
parameters in `kwargs...`.

This function returns a `Vector{OrbitMeanElementsMessage{T}}` with the fetched OMMs. If an
error is found, it returns `nothing`.

!!! warning

    The Space-Track service has limits on the number of requests that can be made in a
    given time period. This function does not handle these limits, so if you make too many
    requests in a short period of time, you may be temporarily blocked from accessing the
    service. Please refer to the
    [Space-Track API documentation](https://www.space-track.org/documentation#/api) for more
    information.

# Keywords

- `T::Type`: The floating-point type to use for the OMM fields. It can be any
    `AbstractFloat`.
    (**Default**: `Float64`)
- `interval::Union{Nothing, Tuple{Union{Date, DateTime}, Union{Date, DateTime}}`: A tuple
    with the start and end date of the interval to fetch the OMMs. This interval is appended
    to the predicates using the `EPOCH` field. If `nothing`, no interval is used. Notice
    that if the space data is `gp` and an interval is specified, the space data is
    automatically changed to `gp_history`.
    (**Default**: `nothing`)
- `order_by::Union{Nothing, Vector{Pair{String, Symbol}}}`: A vector of
    `Pair{String, Symbol}` with the fields to order the results by. The first element of
    each `Pair` is the field name whereas the second is the order direction, which can be
    either `:ascending` or `:descending`. This field is appended to the predicates using the
    `orderby` field. If `nothing`, no ordering is used.
    (**Default**: `nothing`)
- `predicates::Union{Nothing, Vector{Pair{String, Any}}}`: A vector of `Pair{String, Any}`
    with the query predicates to filter the OMMs. The first element of each `Pair` is the
    field name whereas the second is the field value. See the extended help for more
    details. If the field value is of type `HTML{String}`, it is used as is. Otherwise, it
    is converted to a string and URL-encoded.
    (**Default**: `nothing`)
- `query_limits::Union{Nothing, Int, UnitRange{Int}}`: The maximum number of OMMs to fetch.
    If an `Int` is provided, it is used as the limit. If a `UnitRange{Int}` is provided, it
    is used as the start and end indices of the fetched data. If `nothing`, no limit is
    used. This field is appended to the predicates using the `limit` field.
    (**Default**: `nothing`)
- `satellite_name::Union{Nothing, AbstractString}`: The name of the satellite to fetch the
    OMMs. This field is appended to the predicates using the `OBJECT_NAME` field. If
    `nothing`, no satellite name is used. If both `satellite_name` and `satellite_number`
    are provided, `satellite_number` takes precedence.
    (**Default**: `nothing`)
- `satellite_number::Union{Nothing, Number}`: The NORAD catalog number of the satellite to
    fetch the OMMs. This field is appended to the predicates using the `NORAD_CAT_ID` field.
    If `nothing`, no satellite number is used. If both `satellite_name` and
    `satellite_number` are provided, `satellite_number` takes precedence.
    (**Default**: `nothing`)
- `space_data::Symbol`: The space data to fetch the OMMs from. It can be either `:gp` or
    `:gp_history`. If `:gp`, the latest OMM for each satellite is fetched. If `:gp_history`,
    all the OMMs that match the predicates are fetched. If an interval is specified, the
    space data is automatically changed to `:gp_history`. For more information, see the
    [Space-Track API documentation](https://www.space-track.org/documentation#/api).
    (**Default**: `"gp"`)

# Extended Help

## Query Predicates

This section describes the query predicates that can be used to filter the OMMs. Those
expressions can be passed using the `predicates` keyword argument. This description is a
simplified version of the documentation that can be found at
https://www.space-track.org/documentation#/api.

The following fields are available for querying the Space-Track database:

| **Field**               | **Type**                |
|:------------------------|:------------------------|
| CCSDS\\_OMM\\_VERS      | varchar(3)              |
| COMMENT                 | varchar(33)             |
| CREATION\\_DATE         | datetime                |
| ORIGINATOR              | varchar(7)              |
| OBJECT\\_NAME           | varchar(25)             |
| OBJECT\\_ID             | varchar(12)             |
| CENTER\\_NAME           | varchar(5)              |
| REF\\_FRAME             | varchar(4)              |
| TIME\\_SYSTEM           | varchar(3)              |
| MEAN\\_ELEMENT\\_THEORY | varchar(4)              |
| EPOCH                   | datetime(6)             |
| MEAN\\_MOTION           | decimal(13,8)           |
| ECCENTRICITY            | decimal(13,8)           |
| INCLINATION             | decimal(7,4)            |
| RA\\_OF\\_ASC\\_NODE    | decimal(7,4)            |
| ARG\\_OF\\_PERICENTER   | decimal(7,4)            |
| MEAN\\_ANOMALY          | decimal(7,4)            |
| EPHEMERIS\\_TYPE        | tinyint(4)              |
| CLASSIFICATION\\_TYPE   | char(1)                 |
| NORAD\\_CAT\\_ID        | int(10) unsigned        |
| ELEMENT\\_SET\\_NO      | smallint(5) unsigned    |
| REV\\_AT\\_EPOCH        | mediumint(8) unsigned   |
| BSTAR                   | decimal(19,14)          |
| MEAN\\_MOTION\\_DOT     | decimal(9,8)            |
| MEAN\\_MOTION\\_DDOT    | decimal(22,13)          |
| SEMIMAJOR\\_AXIS        | double(12,3)            |
| PERIOD                  | double(12,3)            |
| APOAPSIS                | double(12,3)            |
| PERIAPSIS               | double(12,3)            |
| OBJECT\\_TYPE           | varchar(12)             |
| RCS\\_SIZE              | char(6)                 |
| COUNTRY\\_CODE          | char(6)                 |
| LAUNCH\\_DATE           | date                    |
| SITE                    | char(5)                 |
| DECAY\\_DATE            | date                    |
| FILE                    | bigint(20) unsigned     |
| GP\\_ID                 | int(10) unsigned        |
| TLE\\_LINE0             | varchar(27)             |
| TLE\\_LINE1             | varchar(71)             |
| TLE\\_LINE2             | varchar(71)             |

We can use the following REST operators to build the query predicates:

- `>`: Greater Than (alternate is %3E).
- `<`: Less Than (alternate is %3C).
- `<>`: Not Equal (alternate is %3C%3E).
- `,`: Comma Delimited 'OR' (ex. 1,2,3).
- `--`: Inclusive Range (ex. `1--100` returns 1 and 100 and everything in between). Date
    ranges are expressed as `YYYY-MM-DD%20HH:MM:SS--YYYY-MM-DD%20HH:MM:SS` or
    `YYYY-MM-DD--YYYY-MM-DD`.
- `null-val`: Value for 'NULL', can only be used with Not Equal (<>) or by itself.
- `~~`: "Like" or Wildcard search. You may put the `~~` before or after the text; wildcard
    is evaluated regardless of location of `~~` in the URL. For example, `~~OB` will return
    `'OBJECT 1'`, `'GLOBALSTAR'`, `'PROBA 1'`, etc.
- `^`: Wildcard after value with a minimum of two characters (alternate is %5E). The
    wildcard is evaluated after the text regardless of location of `^` in the URL. For
    example, `^OB` will return `'OBJECT 1'`, `'OBJECT 2'`, etc. but not `'GLOBALSTAR'`.
- `now`: Variable that contains the current system date and time. Add or subtract days (or
    fractions thereof) after `'now'` to modify the date/time, e.g. `now-7`, `now+14`,
    `now-6.5`, `now+2.3`. Use `<`, `>`, and `--` to get a range of dates; e.g. `>now-7`,
    `now-14--now`.

Hence, we can build complex queries like:

1. Return all OMMs where the satellite number is between 40,000 and 40,100 and the mean
    motion is lower than 14.9:

```julia
predicates = [
    "NORAD_CAT_ID" => "40000--40100",
    "MEAN_MOTION"  => "<14.9",
]
```

2. Return all OMMs with epoch in the last 7 days where the right ascension of the ascending
    node (RAAN) is between 140 and 141 degrees:

```julia
predicates = [
    "EPOCH"          => "now-7--now",
    "RA_OF_ASC_NODE" => "140--141",
]
```

3. Return the OMMs for the Starlink satellites that have decayed in the last 10 days:

```julia
predicates = [
    "OBJECT_NAME" => "^STARLINK"
    "EPOCH"       => "now-10--now"
    "DECAY_DATE"  => "<>null-val"
]
```

## Examples

Create the OMM fetcher by logging in to Space-Track.

```julia-repl
julia> f = create_omm_fetcher(SpacetrackOmmFetcher)
Space-Track username: username@email.com
Space-Track password:
[ Info: Successfully logged in to Space-Track.
SpacetrackOmmFetcher: username@email.com (Login expires in 4 hours, 59 minutes, 59 seconds, 999 milliseconds)
```

Fetch all the OMMs for the SCD 1 satellite between June 19 and June 20, 2024.

```julia-repl
julia> omm = fetch_omms(f, satellite_name="SCD 1", interval = (Date(2024, 6, 19), Date(2024, 6, 20)))
3-element Vector{OrbitMeanElementsMessage{Float64}}:
 OMM{Float64}: SCD 1 [1993-009B] (Epoch = 2024-06-19T07:28:48.714816)
 OMM{Float64}: SCD 1 [1993-009B] (Epoch = 2024-06-19T20:30:29.736576)
 OMM{Float64}: SCD 1 [1993-009B] (Epoch = 2024-06-19T22:16:28.479360)
```

Fetch the latest OMM for the Amazonia 1 satellite.

```julia-repl
julia> omm = fetch_omms(f, satellite_name="Amazonia 1")
1-element Vector{OrbitMeanElementsMessage{Float64}}:
 OMM{Float64}: AMAZONIA 1 [2021-015A] (Epoch = 2025-09-09T04:34:22.789920)
```
"""
function fetch_omms(
    fetcher::SpacetrackOmmFetcher;
    T::Type{R} = Float64,
    interval::Union{Nothing, Tuple{D1, D2}} = nothing,
    order_by::Union{Nothing, Vector{Pair{String, Symbol}}} = nothing,
    predicates::Union{Nothing, Vector{Pair{String, P}}} = nothing,
    query_limits::Union{Nothing, Int, UnitRange{Int}} = nothing,
    satellite_name::Union{Nothing, AbstractString} = nothing,
    satellite_number::Union{Nothing, Number} = nothing,
    space_data::Symbol = :gp,
) where {D1 <: Union{Date, DateTime}, D2 <: Union{Date, DateTime}, P, R <: AbstractFloat}
    # Check if the cookie is still valid.
    if !_spacetrack__is_cookie_valid(fetcher.cookiejar)
        @error "The login cookie has expired. Please create a new fetcher instance to login again."
        return nothing
    end

    space_data ∉ (:gp, :gp_history) && throw(ArgumentError(
        "Invalid space data: `$space_data`. It must be either `:gp` or `:gp_history`."
    ))

    # == Query Predicates ==================================================================

    query_predicates = Pair{String, Union{HTML{String}, String}}[]

    # -- Time Interval ---------------------------------------------------------------------

    if !isnothing(interval)
        start_date = DateTime(first(interval))
        end_date   = DateTime(last(interval))

        start_date >= end_date && throw(ArgumentError(
            "The start date must be earlier than the end date."
        ))

        v =
            Dates.format(start_date, "YYYY-mm-dd%20HH:MM:SS") *
            "--" *
            Dates.format(end_date, "YYYY-mm-dd%20HH:MM:SS")

        push!(query_predicates, "EPOCH" => HTML{String}(v))

        # If the interval is specified and the space data is "gp", we switch to
        # "gp_history".
        if space_data == :gp
            @debug "The space data was changed to `:gp_history` because an interval was specified."
            space_data = :gp_history
        end
    end

    # -- Order By --------------------------------------------------------------------------

    if !isnothing(order_by)
        order_by_predicate = ""

        for (field, direction) in order_by
            direction ∉ (:ascending, :descending) && throw(ArgumentError("""
                Invalid order direction (`$direction`) for the field `$field`. It must be
                either `:ascending` or `:descending`.
                """
            ))

            dir_str = direction == :ascending ? "asc" : "desc"
            order_by_predicate *=
                isempty(order_by_predicate) ? "$field%20$dir_str" : ",$field $dir_str"
        end

        !isempty(order_by_predicate) &&
            push!(query_predicates, "orderby" => HTML{String}(order_by_predicate))
    end

    # -- Query Limits ----------------------------------------------------------------------

    if !isnothing(query_limits)
        if query_limits isa UnitRange
            l₀ = query_limits.start
            l₀ < 1 && throw(ArgumentError(
                "The start of the query limits must be greater than or equal to 1."
            ))

            Δl = length(query_limits)
            Δl <= 0 && throw(ArgumentError(
                "The end of the query limits must be greater than or equal to the start."
            ))

            v = "$Δl,$(l₀ - 1)"
            push!(query_predicates, "limit" => HTML{String}(v))
        else
            query_limits < 1 && throw(ArgumentError(
                "The query limits must be greater than or equal to 1."
            ))

            push!(query_predicates, "limit" => HTML{String}(string(query_limits)))
        end
    end

    # -- Satellite Name / Number -----------------------------------------------------------

    if !isnothing(satellite_number)
        # The satellite number must be positive.
        satellite_number < 0 && throw(ArgumentError("The satellite number must be positive."))

        push!(query_predicates, "NORAD_CAT_ID" => string(satellite_number))

    elseif !isnothing(satellite_name)
        isempty(satellite_name) && throw(ArgumentError("The satellite name is empty."))

        push!(query_predicates, "OBJECT_NAME" => satellite_name)
    end

    # -- Other Predicates ------------------------------------------------------------------

    !isnothing(predicates) && for (k, v) in predicates
        push!(query_predicates, k => v isa HTML{String} ? v : string(v))
    end

    # == Build Query URL ===================================================================

    raw_query = ""

    for (key, value) in query_predicates
        v = value isa HTML{String} ? value.content : URIs.escapeuri(string(value))
        raw_query *= "/$key/$v"
    end

    isnothing(raw_query) && return nothing

    space_data_str = string(space_data)

    query_url =
        "$_SPACETRACK__URL/basicspacedata/query/class/$space_data_str$raw_query/format/xml"

    @debug "Query URL: $query_url"

    # == Fetch Data ========================================================================

    try
        response = HTTP.request(
            "GET",
            query_url,
            cookiejar = fetcher.cookiejar,
            cookies   = true,
        )

        if response.status != 200
            @error """
                An error occurred during the data request:
                  HTTP Error Code : $(response.status)
                  Query URL       : $query_url
                """
            return nothing
        end

        xml  = parse(String(response.body), LazyNode)
        omms = parse_omms(xml, T)

        if isnothing(omms)
            @error "Could not parse the fetched OMMs."
            return nothing
        end

        # If the request is successful, we need to save the cookiejar because the expire
        # period may have been updated.
        _spacetrack__save_cookiejar(fetcher.cookiejar, fetcher.username)

        return omms

    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            @error """
                An error occurred during the data request:
                  HTTP Error Code : $(e.status)
                  Query URL       : $query_url
                """

            return nothing
        end

        rethrow(e)
    end
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _spacetrack__cookie_expire_date(cookiejar::HTTP.CookieJar) -> Union{DateTime, Nothing}

Get the expiration date of the spacetrack cookie in the `cookiejar`. If the cookie is not
found, it returns `nothing`.
"""
function _spacetrack__cookie_expire_date(cookiejar::HTTP.CookieJar)
    !haskey(cookiejar.entries, _SPACETRACK__HOST) && return nothing
    cookie_path = _SPACETRACK__HOST * ";/;" * _SPACETRACK__COOKIE_NAME
    entries     = cookiejar.entries[_SPACETRACK__HOST]

    !haskey(entries, cookie_path) && return nothing
    expires = entries[cookie_path].expires

    return expires
end

"""
    _spacetrack__is_cookie_valid(cookiejar::Union{HTTP.CookieJar, Nothing}) -> Bool

Check if the spacetrack cookie in the `cookiejar` is valid. To load the `cookiejar`, use
the function `_spacetrack__load_cookiejar`.
"""
_spacetrack__is_cookie_valid(::Nothing) = false

function _spacetrack__is_cookie_valid(cookiejar::HTTP.CookieJar)
    expires = _spacetrack__cookie_expire_date(cookiejar)
    return expires > Dates.now()
end

"""
    _spacetrack__load_cookiejar(username::String) -> Union{HTTP.CookieJar, Nothing}

Load the cookie jar for the given `username` from the scratch space. If the cookie file does
not exist or could not be loaded, it returns `nothing`.
"""
function _spacetrack__load_cookiejar(username::String)
    cache_dir   = @get_scratch!("spacetrack")
    cookie_file = joinpath(cache_dir, "cookies-$username")

    # If the cookie file does not exist, return nothing.
    !isfile(cookie_file) && return nothing

    # Load the cookies from the file.
    try
        cookie_entries = deserialize(cookie_file)
        cookiejar      = HTTP.CookieJar()

        for entry in cookie_entries
            push!(cookiejar.entries, entry)
        end

        return cookiejar
    catch e
        @error """
            Could not load cookies from file.
              $e
            """
        return nothing
    end
end

"""
    _spacetrack__login(username::String, password::String) -> Bool

Login to the Space-Track service using the provided `username` and `password`. If the login
is successful, it saves the cookies to the scratch space and returns `true`. If the login
fails, it returns `false`.
"""
function _spacetrack__login(username::String, password::String)
    try
        login_data =
            "identity=$(URIs.escapeuri(username))&" *
            "password=$(URIs.escapeuri(password))"

        cookiejar = HTTP.CookieJar()

        response = HTTP.request(
            "POST",
            _SPACETRACK__LOGIN_URL,
            body      = login_data,
            cookiejar = cookiejar,
            cookies   = true,
            headers   = Dict("Content-Type" => "application/x-www-form-urlencoded"),
        )

        # If the body contains "Failed", it means the login failed.
        if occursin("Failed", String(response.body))
            @error "Login failed: Invalid username or password."
            return false, nothing
        end

        @info "Successfully logged in to Space-Track."

        # Save the cookie to the scratch space.
        _spacetrack__save_cookiejar(cookiejar, username)

        return true, cookiejar

    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            msg = isnothing(e.response) ? "No server response" : String(e.response.body)
            @error """
                An error occurred during the login request:
                  HTTP Error Code : $(e.status)
                  Server message  : $msg
                """

            return false, nothing
        end

        rethrow(e)
    end
end

"""
    _spacetrack__save_cookiejar(cookiejar::HTTP.CookieJar, username::String) -> Nothing

Save the `cookiejar` to the scratch space for the given `username`.
"""
function _spacetrack__save_cookiejar(cookiejar::HTTP.CookieJar, username::String)
    cache_dir   = @get_scratch!("spacetrack")
    cookie_file = joinpath(cache_dir, "cookies-$username")
    serialize(cookie_file, cookiejar.entries)

    return nothing
end
