## Description #############################################################################
#
# Define the functions for the API of the ODM fetchers.
#
############################################################################################

# == Orbit Data Message Fetchers ===========================================================

export create_omm_fetcher, fetch_omms
export OdmFetchError, OdmLoginError

# == Exceptions ============================================================================

"""
    struct OdmLoginError <: Exception

Exception thrown when the authentication with an Orbit Data Message service fails.

# Fields

- `msg::String`: Description of the login failure.
"""
struct OdmLoginError <: Exception
    msg::String
end

Base.showerror(io::IO, e::OdmLoginError) = print(io, "OdmLoginError: ", e.msg)

"""
    struct OdmFetchError <: Exception

Exception thrown when a request to an Orbit Data Message service fails.

# Fields

- `msg::String`: Description of the request failure.
- `url::Union{String, Nothing}`: URL of the failed request, if available.
    (**Default**: `nothing`)
- `status::Union{Int, Nothing}`: HTTP status code of the failed request, if available.
    (**Default**: `nothing`)
"""
struct OdmFetchError <: Exception
    msg::String
    url::Union{String, Nothing}
    status::Union{Int, Nothing}
end

function OdmFetchError(
    msg::String;
    url::Union{String, Nothing} = nothing,
    status::Union{Int, Nothing} = nothing
)
    return OdmFetchError(msg, url, status)
end

function Base.showerror(io::IO, e::OdmFetchError)
    print(io, "OdmFetchError: ", e.msg)
    isnothing(e.status) || print(io, " (HTTP status: ", e.status, ")")
    isnothing(e.url) || print(io, "\nURL: ", e.url)
    return nothing
end

"""
    create_omm_fetcher(::Type{T}, args...; kwargs...) where T <: AbstractOmmFetcher -> T

Create an Orbit Mean-Elements Message (OMM) fetcher of type `T`.
"""
function create_omm_fetcher(::Type{T}, args...; kwargs...) where T <: AbstractOmmFetcher
    throw(ArgumentError("The OMM fetcher $T is not registered."))
end

"""
    fetch_omms(fetcher::T; kwargs...) -> Vector{OrbitMeanElementsMessage}

Fetch Orbit Mean-Elements Messages (OMM) using `fetcher`.

The keywords `kwargs...` are used to customize the search. It depends on the fetcher type
`T`.
"""
function fetch_omms(::T; kwargs...) where T <: AbstractOmmFetcher
    throw(ArgumentError("The OMM fetcher $T is not registered."))
end
