## Description #############################################################################
#
# Functions to write Orbit Mean-Elements Message (OMM) files.
#
############################################################################################

export write_omm

"""
    write_omm(io::IO, omm::OrbitMeanElementsMessage; kwargs...) -> Nothing

Write the given `omm` to the provided `io` stream.

    write_omm(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage}; kwargs...) -> Nothing

Write the set of Orbit Mean-Elements Messages in the vector `vomm` to the provided `io`
stream. In XML format, the messages are wrapped in a Navigation Data Message (NDM) document,
whereas in KVN format they are written sequentially, delimited by their `CCSDS_OMM_VERS`
keyword.

    write_omm(file::AbstractString, omm::OrbitMeanElementsMessage; kwargs...) -> Nothing
    write_omm(
        file::AbstractString,
        vomm::AbstractVector{OrbitMeanElementsMessage};
        kwargs...
    ) -> Nothing

Write the given `omm` (or the set of messages in `vomm`) to the file at `file`, overwriting
its contents.

The written version is always `3.0`, regardless of the version stored in the messages.

# Keywords

- `format::Symbol`: The output format, which can be `:xml` or `:kvn`. The methods that
    write to a file also accept `:auto`, which infers the format from the file extension
    (case-insensitive): `.kvn` selects the KVN format, whereas any other extension selects
    the XML format.
    (**Default**: `:xml` when writing to an `io` stream, `:auto` when writing to a file)
"""
function write_omm(
    io::IO,
    omm::Union{OrbitMeanElementsMessage, AbstractVector{OrbitMeanElementsMessage}};
    format::Symbol = :xml,
)
    _odm_check_output_format(format)
    _omm_check_writable(omm, format)
    _omm_write(io, omm, format)
    return nothing
end

function write_omm(
    file::AbstractString,
    omm::Union{OrbitMeanElementsMessage, AbstractVector{OrbitMeanElementsMessage}};
    format::Symbol = :auto,
)
    # Validate everything before opening the file so that a failure does not truncate an
    # existing output file.
    format = _odm_output_format(file, format)
    _omm_check_writable(omm, format)

    open(file, "w") do io
        return _omm_write(io, omm, format)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _omm_write(
        io::IO,
        omm::Union{OrbitMeanElementsMessage, AbstractVector{OrbitMeanElementsMessage}},
        format::Symbol
    ) -> Nothing

Write the message (or messages) `omm` to `io` in the given `format`, which must be `:xml`
or `:kvn`. The messages must have been validated with [`_omm_check_writable`](@ref).
"""
function _omm_write(
    io::IO,
    omm::Union{OrbitMeanElementsMessage, AbstractVector{OrbitMeanElementsMessage}},
    format::Symbol,
)
    format == :xml && return _xml_omm__write(io, omm)
    return _kvn_omm__write(io, omm)
end

"""
    _omm_check_writable(omm::OrbitMeanElementsMessage, format::Symbol) -> Nothing
    _omm_check_writable(
        vomm::AbstractVector{OrbitMeanElementsMessage},
        format::Symbol
    ) -> Nothing

Check if `omm` (or every message in `vomm`) contains all fields required to write an OMM
3.0 output as `format`, throwing an `ArgumentError` otherwise.

The format-independent rules are shared by every format, whereas `format` selects the
additional format-specific rules (currently, the KVN keyword grammar for the user-defined
parameter names).
"""
function _omm_check_writable(omm::OrbitMeanElementsMessage, format::Symbol)
    isnothing(omm.header.creation_date) &&
        throw(ArgumentError("Cannot write OMM 3.0 without a creation date."))

    isempty(omm.header.originator) &&
        throw(ArgumentError("Cannot write OMM 3.0 without an originator."))

    format == :kvn && _kvn_omm__check_user_defined_keys(omm)

    return nothing
end

function _omm_check_writable(
    vomm::AbstractVector{OrbitMeanElementsMessage}, format::Symbol
)
    foreach(omm -> _omm_check_writable(omm, format), vomm)
    return nothing
end
