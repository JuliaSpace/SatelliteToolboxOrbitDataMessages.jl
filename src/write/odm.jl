## Description #############################################################################
#
# Functions to write Orbit Data Messages (ODM).
#
############################################################################################

export write_odm

"""
    write_odm(io::IO, odm::OrbitDataMessage) -> Nothing

Write the given `odm` to the provided `io` stream in XML format.

    write_odm(io::IO, vodm::AbstractVector{T}) where T<:OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the provided `io` stream in XML
format.

    write_odm(file::AbstractString, odm::OrbitDataMessage) -> Nothing

Write the given `odm` to the file at `file` in XML format, overwriting its contents.

    write_odm(file::AbstractString, vodm::AbstractVector{T}) where T<:OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the file at `file` in XML
format, overwriting its contents.
"""
write_odm(io::IO, odm::OrbitDataMessage) = write_odm(io, [odm])

function write_odm(io::IO, vodm::AbstractVector{T}) where {T <: OrbitDataMessage}
    # Check if the messages contain all fields required for writing.
    foreach(_odm_check_writable, vodm)

    # Write the messages using the desired file type.
    _xml_odm__write(io, vodm)

    return nothing
end

function write_odm(file::AbstractString, odm::OrbitDataMessage)
    open(file, "w") do io
        return write_odm(io, odm)
    end

    return nothing
end

function write_odm(
    file::AbstractString, vodm::AbstractVector{T}
) where {T <: OrbitDataMessage}
    open(file, "w") do io
        return write_odm(io, vodm)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _odm_check_writable(odm::OrbitDataMessage) -> Nothing

Check if `odm` contains all fields required for writing, throwing an `ArgumentError`
otherwise. The check is dispatched to the corresponding message type; unsupported message
types are accepted here and skipped with a warning by the format-specific writer.

This function is format-agnostic so that every supported file type is validated by the
same rules.
"""
_odm_check_writable(omm::OrbitMeanElementsMessage) = _omm_check_writable(omm)

_odm_check_writable(::OrbitDataMessage) = nothing
