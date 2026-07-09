## Description #############################################################################
#
# Create the Celestrak OMM fetcher.
#
############################################################################################

export CelestrakOmmFetcher

"""
    struct CelestrakOmmFetcher <: AbstractOmmFetcher

Fetcher that retrieves Orbit Mean-Elements Messages (OMM) from the
[Celestrak](https://celestrak.org) service.

Create an instance with
[`create_omm_fetcher(CelestrakOmmFetcher)`](@ref create_omm_fetcher) and query the service
with [`fetch_omms`](@ref). Celestrak provides publicly available data and does not require
authentication.

# Fields

- `url::String`: Address of the Celestrak endpoint used to perform the queries.
"""
struct CelestrakOmmFetcher <: AbstractOmmFetcher
    url::String
end

############################################################################################
#                                        Julia API                                         #
############################################################################################

function Base.show(io::IO, fetcher::CelestrakOmmFetcher)
    print(io, "CelestrakOmmFetcher: $(fetcher.url)")
    return nothing
end

"""
    create_omm_fetcher(::Type{CelestrakOmmFetcher}; kwargs...) -> CelestrakOmmFetcher

Create an Orbit Mean-Elements Message (OMM) fetcher from Celestrak service.

# Keywords

- `url::String`: Default URL of the Celestrak PHP query endpoint.
  (**Default**: "https://celestrak.org/NORAD/elements/gp.php")
"""
function create_omm_fetcher(
    ::Type{CelestrakOmmFetcher};
    url::String = "https://celestrak.org/NORAD/elements/gp.php"
)
    return CelestrakOmmFetcher(url)
end

"""
    fetch_omms(fetcher::CelestrakOmmFetcher; kwargs...) -> Union{Nothing, Vector{OrbitMeanElementsMessage}}

Fetch Orbit Mean-Elements Messages (OMM) from the Celestrak using `fetch` with the
parameters in `kwargs...`.

This function returns a `Vector{OrbitMeanElementsMessage}` with the fetched OMMs. If no
matching OMM is found, an empty vector is returned. If an error prevents the request from
succeeding, it returns `nothing`.
"""
function fetch_omms(
    fetcher::CelestrakOmmFetcher;
    international_designator::Union{Nothing, AbstractString} = nothing,
    satellite_number::Union{Nothing, Number} = nothing,
    satellite_name::Union{Nothing, AbstractString} = nothing,
)

    # Assemble the query string.
    if !isnothing(satellite_number)

        # The satellite number must be positive.
        satellite_number < 0 && throw(ArgumentError("The satellite number must be positive."))

        query_type  = "satellite number"
        query_value = string(satellite_number)
        query_param = "CATNR=" * URIs.escapeuri(query_value)

    elseif !isnothing(international_designator)
        # The international designator must be a string with the form:
        #
        #   YYYY-NNN[P]
        #
        # where `YYYY` is the launch year, `NNN` is the launch number (1 to 3 digits),
        # and `P` is an optional piece letter.

        m = match(r"^(\d{4})-(\d{1,3})([A-Z]*)$", international_designator)

        isnothing(m) && return throw(ArgumentError(
            "The international designator must have the format `YYYY-NNN` or `YYYY-NNNP`."
        ))

        # Pad the launch number to 3 digits as expected by Celestrak's INTDES parameter.
        query_value = string(m.captures[1], "-", lpad(m.captures[2], 3, "0"), m.captures[3])

        query_type  = "international designator"
        query_param = "INTDES=" * URIs.escapeuri(query_value)

    elseif !isnothing(satellite_name)
        isempty(satellite_name) && throw(ArgumentError("The satellite name is empty."))

        query_value = satellite_name
        query_param = "NAME=" * URIs.escapeuri(query_value)
        query_type  = "satellite name"

    else
        throw(ArgumentError("No query information was provided."))

    end

    @info "Fetch Orbit Mean-Elements Messages (OMMs) from Celestrak using $query_type: \"$query_value\" ..."

    # Assemble the URL.
    query = "?" * query_param * "&FORMAT=xml"
    url = fetcher.url * query

    # Fetch the data.
    @debug "Fetch URL: $url"

    try
        response = HTTP.request("GET", url)

        if response.status != 200
            @error """
                An error occurred during the data request:
                  HTTP Error Code : $(response.status)
                  Query URL       : $url
                """
            return nothing
        end

        str = String(response.body)

        # Check if some error occurred.
        if !isnothing(match(r"No GP data found", str))
            @warn "No OMM found."
            return OrbitMeanElementsMessage[]

        elseif !isnothing(match(r"Invalid query", str))
            return throw(ErrorException("Invalid query: $query"))
        end

        xml  = parse(str, LazyNode)
        omms = parse_omms(xml)

        if isnothing(omms)
            @error "Could not parse the fetched OMMs."
            return nothing
        end

        return omms

    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            @error """
                An error occurred during the data request:
                  HTTP Error Code : $(e.status)
                  Query URL       : $url
                """

            return nothing
        end

        rethrow(e)
    end
end
