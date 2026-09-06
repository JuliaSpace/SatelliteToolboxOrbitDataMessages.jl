## Description #############################################################################
#
# Parse a set of Orbit Mean-Elements Messages (OMM) using KVN input.
#
############################################################################################

"""
    _kvn_omms__parse(str::AbstractString) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) in the KVN input `str` and return the
parsed messages. Messages of other types are skipped with a warning (see
[`_kvn_odm__parse`](@ref)).
"""
function _kvn_omms__parse(str::AbstractString)
    messages = _kvn_odm__parse(str)

    # Keep only the OMM messages, skipping the other types.
    return OrbitMeanElementsMessage[
        message for message in messages if message isa OrbitMeanElementsMessage
    ]
end
