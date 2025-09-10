## Description #############################################################################
#
# Define the functions for the API of the ODM fetchers.
#
############################################################################################

# == Orbit Data Message Fetchers ===========================================================

export create_omm_fetcher, fetch_omms

"""
    create_omm_fetcher(::Type{T}, args...; kwargs...) where T <: AbstractommFetcher -> T

Create an Orbit Mean-Elements Message (OMM) fetcher of type `T`.
"""
function create_omm_fetcher(::Type{T}, args...; kwargs...) where T <: AbstractOmmFetcher
    error("The OMM fetcher $T is not registered.")
end

"""
    fetch_omms(fetcher::T; kwargs...) -> Vector{omm}

Fetch Orbit Mean-Elements Messages (OMM) using `fetcher`.

The keywords `kwargs...` are used to customize the search. It depends on the fetcher type
`T`.
"""
function fetch_omms(::T; kwargs...) where T <: AbstractOmmFetcher
    error("The OMM fetcher $T is not registered.")
end
