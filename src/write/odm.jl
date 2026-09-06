## Description #############################################################################
#
# Functions to write Orbit Data Messages (ODM).
#
############################################################################################

export write_odm

"""
    write_odm(io::IO, odm::OrbitDataMessage; kwargs...) -> Nothing
    write_odm(io::IO, vodm::AbstractVector{T}; kwargs...) where T<:OrbitDataMessage -> Nothing

Write the given `odm` (or the set of messages in `vodm`) to the provided `io` stream. In
the XML format, the messages are wrapped in a Navigation Data Message (NDM) document,
whereas in the KVN format they are written sequentially, each one starting at its version
keyword.

    write_odm(file::AbstractString, odm::OrbitDataMessage; kwargs...) -> Nothing
    write_odm(
        file::AbstractString,
        vodm::AbstractVector{T};
        kwargs...
    ) where T<:OrbitDataMessage -> Nothing

Write the given `odm` (or the set of messages in `vodm`) to the file at `file`, overwriting
its contents.

Message types that cannot be written yet are skipped with a warning.

# Keywords

- `format::Symbol`: The output format, which can be `:xml` or `:kvn`. The methods that
    write to a file also accept `:auto`, which infers the format from the file extension
    (case-insensitive): `.kvn` selects the KVN format, whereas any other extension selects
    the XML format.
    (**Default**: `:xml` when writing to an `io` stream, `:auto` when writing to a file)
"""
function write_odm(io::IO, odm::OrbitDataMessage; format::Symbol = :xml)
    return write_odm(io, [odm]; format)
end

function write_odm(
    io::IO, vodm::AbstractVector{T}; format::Symbol = :xml
) where {T <: OrbitDataMessage}
    _odm_check_output_format(format)

    # Check if the messages contain all fields required for writing.
    foreach(odm -> _odm_check_writable(odm, format), vodm)

    # Write the messages using the desired format.
    format == :xml && return _xml_odm__write(io, vodm)

    return _kvn_odm__write(io, vodm)
end

function write_odm(
    file::AbstractString,
    odm::Union{OrbitDataMessage, AbstractVector{<:OrbitDataMessage}};
    format::Symbol = :auto,
)
    # Validate everything before opening the file so that a failure does not truncate an
    # existing output file.
    format = _odm_output_format(file, format)

    if odm isa AbstractVector
        foreach(o -> _odm_check_writable(o, format), odm)
    else
        _odm_check_writable(odm, format)
    end

    open(file, "w") do io
        return write_odm(io, odm; format)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _odm_check_writable(odm::OrbitDataMessage, format::Symbol) -> Nothing

Check if `odm` contains all fields required for writing it as `format`, throwing an
`ArgumentError` otherwise. The check is dispatched to the corresponding message type;
unsupported message types are accepted here and skipped with a warning by the
format-specific writer.
"""
_odm_check_writable(omm::OrbitMeanElementsMessage, format::Symbol) =
    _omm_check_writable(omm, format)

_odm_check_writable(::OrbitDataMessage, ::Symbol) = nothing
