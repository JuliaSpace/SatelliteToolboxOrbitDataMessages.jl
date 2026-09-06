## Description #############################################################################
#
# Write Orbit Data Messages (ODM) using KVN output.
#
############################################################################################

"""
    _kvn_odm__write(io::IO, vodm::AbstractVector{T}) where T <: OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the provided `io` stream in
KVN format. The messages are written sequentially, each one starting at its version
keyword.
"""
function _kvn_odm__write(io::IO, vodm::AbstractVector{T}) where {T <: OrbitDataMessage}
    for odm in vodm
        _kvn_odm__write_message(io, odm)
    end

    return nothing
end

"""
    _kvn_odm__write_message(io::IO, odm::OrbitDataMessage) -> Nothing

Write `odm` to the provided `io` stream in KVN format. Message types that cannot be written
yet emit a warning and are skipped.

To add support for a new message type, define a method for the corresponding concrete
type.
"""
_kvn_odm__write_message(io::IO, omm::OrbitMeanElementsMessage) = _kvn_omm__write(io, omm)

function _kvn_odm__write_message(::IO, odm::OrbitDataMessage)
    @warn "Skipping unsupported message of type $(typeof(odm)) during ODM writing."
    return nothing
end
