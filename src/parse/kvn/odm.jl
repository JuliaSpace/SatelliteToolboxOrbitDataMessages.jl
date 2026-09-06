## Description #############################################################################
#
# Parse Orbit Data Messages (ODM) using KVN input.
#
############################################################################################

"""
    _kvn_odm__parse(str::AbstractString) -> Vector{OrbitDataMessage}

Parse the Orbit Data Messages (ODM) in the KVN input `str`, returning a vector with the
parsed messages. Only OMMs are supported in the KVN format currently, so the result holds
the messages returned by [`_kvn_omms__parse`](@ref).
"""
_kvn_odm__parse(str::AbstractString) = Vector{OrbitDataMessage}(_kvn_omms__parse(str))
