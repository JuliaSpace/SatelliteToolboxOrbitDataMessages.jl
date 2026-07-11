# [Fetching from Services](@id Fetching-from-Services)

```@meta
CurrentModule = SatelliteToolboxOrbitDataMessages
```

This package can fetch Orbit Mean-Elements Messages (OMM) directly from online services. It
currently supports two providers:

| **Service**                                | **Fetcher Type**        | **Authentication** |
|:-------------------------------------------|:------------------------|:-------------------|
| [Celestrak](https://celestrak.org)         | [`CelestrakOmmFetcher`](@ref) | None (public)      |
| [Space-Track](https://www.space-track.org) | [`SpacetrackOmmFetcher`](@ref) | Free account       |

The workflow is always the same:

1. Create a fetcher with [`create_omm_fetcher`](@ref).
2. Query the service with [`fetch_omms`](@ref).

[`fetch_omms`](@ref) returns a `Vector{OrbitMeanElementsMessage}` on success (possibly
empty). If the authentication fails or expires, an [`OdmLoginError`](@ref) is thrown. If
the request to the service fails, an [`OdmFetchError`](@ref) is thrown.

!!! note

    The examples on this page perform live network requests and therefore are **not**
    executed while building this documentation. The outputs shown are illustrative.

## Celestrak

[Celestrak](https://celestrak.org) provides publicly available orbit data and does not
require authentication. Create the fetcher with:

```julia
julia> fetcher = create_omm_fetcher(CelestrakOmmFetcher)
```

We can then query OMMs by satellite catalog number, international designator, or name:

```julia
# By NORAD catalog number.
julia> omms = fetch_omms(fetcher; satellite_number = 47699)

# By international designator (format `YYYY-NNN`).
julia> omms = fetch_omms(fetcher; international_designator = "2021-015")

# By satellite name (supports partial matches).
julia> omms = fetch_omms(fetcher; satellite_name = "AMAZONIA 1")
1-element Vector{OrbitMeanElementsMessage}:
 OMM: AMAZONIA 1 [2021-015A] (Epoch = 2025-12-30T18:12:04.533984)
```

Exactly one query keyword must be provided. See [`create_omm_fetcher`](@ref) and
[`fetch_omms`](@ref) for the complete list of options.

## Space-Track

[Space-Track](https://www.space-track.org) offers a much richer query interface but requires
a (free) registered account. When creating the fetcher, you will be prompted for your
credentials if they are not provided as keywords:

```julia
julia> fetcher = create_omm_fetcher(SpacetrackOmmFetcher)
Space-Track username: username@email.com
Space-Track password:
[ Info: Successfully logged in to Space-Track.
SpacetrackOmmFetcher: username@email.com (Login expires in 4 hours, 59 minutes, 59 seconds)
```

!!! tip

    A valid login cookie is cached locally, so subsequent sessions reuse it without
    prompting for the password again until it expires. Pass `force_login = true` to force a
    new login.

### Simple Queries

Just like Celestrak, we can query by satellite name or catalog number:

```julia
julia> omms = fetch_omms(fetcher; satellite_name = "AMAZONIA 1")
1-element Vector{OrbitMeanElementsMessage}:
 OMM: AMAZONIA 1 [2021-015A] (Epoch = 2025-09-09T04:34:22.789920)
```

By default, only the **latest** OMM for each object is returned. To retrieve the historical
data over a time interval, pass the `interval` keyword. This automatically switches the
query to the `gp_history` data source:

```julia
julia> omms = fetch_omms(
           fetcher;
           satellite_name = "SCD 1",
           interval = (Date(2024, 6, 19), Date(2024, 6, 20))
       )
3-element Vector{OrbitMeanElementsMessage}:
 OMM: SCD 1 [1993-009B] (Epoch = 2024-06-19T07:28:48.714816)
 OMM: SCD 1 [1993-009B] (Epoch = 2024-06-19T20:30:29.736576)
 OMM: SCD 1 [1993-009B] (Epoch = 2024-06-19T22:16:28.479360)
```

### Advanced Queries

Space-Track supports complex filtering through **query predicates**. Each predicate is a
`Pair` mapping a field name to a value, using the REST operators documented by Space-Track.
For example, to fetch all objects whose catalog number is between 40,000 and 40,100 and
whose mean motion is lower than 14.9:

```julia
julia> omms = fetch_omms(
           fetcher;
           predicates = [
               "NORAD_CAT_ID" => "40000--40100",
               "MEAN_MOTION"  => "<14.9",
           ]
       )
```

We can also order the results and limit the number of returned messages:

```julia
julia> omms = fetch_omms(
           fetcher;
           predicates   = ["OBJECT_NAME" => "^STARLINK"],
           order_by     = ["EPOCH" => :descending],
           query_limits = 10,
       )
```

The complete list of available fields, operators, and options is described in the docstring
of [`fetch_omms`](@ref) (see its extended help) and in the
[Space-Track API documentation](https://www.space-track.org/documentation#/api).

!!! warning

    Space-Track enforces rate limits on its API. This package does not throttle requests, so
    avoid issuing too many queries in a short period to prevent being temporarily blocked.

## Saving Fetched Data

Once fetched, the messages are ordinary [`OrbitMeanElementsMessage`](@ref) objects. They can
be inspected, [converted to a TLE](@ref Converting-to-TLE), or written to disk as an NDM
with [`write_odm`](@ref):

```julia
open("fetched.xml", "w") do io
    write_odm(io, omms)
end
```
