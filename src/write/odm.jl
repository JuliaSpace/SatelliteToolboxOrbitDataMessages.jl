## Description #############################################################################
#
# Functions to write Orbit Data Messages (ODM).
#
############################################################################################

export write_odm

"""
    write_odm(io::IO, odm::OrbitDataMessage; kwargs...) -> Nothing
    write_odm(
        io::IO,
        vodm::AbstractVector{T};
        kwargs...
    ) where T<:OrbitDataMessage -> Nothing

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
function write_odm(
    io::IO,
    odm::Union{OrbitDataMessage, AbstractVector{<:OrbitDataMessage}};
    format::Symbol = :xml,
)
    _odm_check_output_format(format)
    _odm_check_writable(odm, format)
    _odm_write(io, odm, format)
    return nothing
end

function write_odm(
    file::AbstractString,
    odm::Union{OrbitDataMessage, AbstractVector{<:OrbitDataMessage}};
    format::Symbol = :auto,
)
    # Validate everything before opening the file so that a failure does not truncate an
    # existing output file.
    format = _odm_output_format(file, format)
    _odm_check_writable(odm, format)

    open(file, "w") do io
        return _odm_write(io, odm, format)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _odm_write(
        io::IO,
        odm::Union{OrbitDataMessage, AbstractVector{<:OrbitDataMessage}},
        format::Symbol
    ) -> Nothing

Write the message (or messages) `odm` to `io` in the given `format`, which must be `:xml`
or `:kvn`. A single message is written as a one-element set. The messages must have been
validated with [`_odm_check_writable`](@ref).
"""
_odm_write(io::IO, odm::OrbitDataMessage, format::Symbol) = _odm_write(io, [odm], format)

function _odm_write(
    io::IO, vodm::AbstractVector{<:OrbitDataMessage}, format::Symbol
)
    format == :xml && return _xml_odm__write(io, vodm)
    return _kvn_odm__write(io, vodm)
end

"""
    _odm_check_writable(odm::OrbitDataMessage, format::Symbol) -> Nothing
    _odm_check_writable(vodm::AbstractVector{<:OrbitDataMessage}, format::Symbol) -> Nothing

Check if `odm` (or every message in `vodm`) contains all fields required for writing it as
`format`, throwing an `ArgumentError` otherwise. The check is dispatched to the
corresponding message type; unsupported message types are accepted here and skipped with a
warning by the format-specific writer.
"""
_odm_check_writable(omm::OrbitMeanElementsMessage, format::Symbol) =
    _omm_check_writable(omm, format)

_odm_check_writable(::OrbitDataMessage, ::Symbol) = nothing

function _odm_check_writable(vodm::AbstractVector{<:OrbitDataMessage}, format::Symbol)
    foreach(odm -> _odm_check_writable(odm, format), vodm)
    return nothing
end
