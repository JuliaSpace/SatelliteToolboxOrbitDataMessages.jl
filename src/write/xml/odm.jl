## Description #############################################################################
#
# Write Orbit Data Messages (ODM) using XML output.
#
############################################################################################

"""
    _xml_odm__write(io::IO, vodm::AbstractVector{T}) where T <: OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the provided `io` stream as a
Navigation Data Message (NDM) XML document.
"""
function _xml_odm__write(io::IO, vodm::AbstractVector{T}) where {T <: OrbitDataMessage}
    println(io, _XML__DECLARATION)
    print(io, "<ndm ", _XML__SCHEMA_ATTRIBUTES, ">\n")

    for odm in vodm
        _xml_odm__write_message(io, odm, 1)
    end

    print(io, "</ndm>\n")

    return nothing
end

"""
    _xml_odm__write_message(io::IO, odm::OrbitDataMessage, level::Int) -> Nothing

Write `odm` to the provided `io` stream as an XML element at the indentation `level`,
suitable for embedding in an NDM document. Message types that cannot be written yet emit a
warning and are skipped.

To add support for a new message type, define a method for the corresponding concrete
type.
"""
function _xml_odm__write_message(io::IO, omm::OrbitMeanElementsMessage, level::Int)
    return _xml_omm__write_element(io, omm, level)
end

function _xml_odm__write_message(::IO, odm::OrbitDataMessage, ::Int)
    @warn "Skipping unsupported message of type $(typeof(odm)) during ODM writing."
    return nothing
end
