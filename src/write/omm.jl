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

- `file_type::Symbol`: The output file type, which can be `:xml` or `:kvn`. The methods that
    write to a file also accept `:auto`, which infers the file type from the file extension
    (case-insensitive): `.kvn` selects the KVN format, whereas any other extension selects
    the XML format.
    (**Default**: `:xml` when writing to an `io` stream, `:auto` when writing to a file)
"""
function write_omm(io::IO, omm::OrbitMeanElementsMessage; file_type::Symbol = :xml)
    # Check if the message contains all fields required for writing.
    _omm_check_writable(omm)

    # Write the message using the desired file type.
    file_type == :xml && return _xml_omm__write(io, omm)
    file_type == :kvn && return _kvn_omm__write(io, omm)

    return throw(ArgumentError("Unsupported file type: $file_type."))
end

function write_omm(
    io::IO, vomm::AbstractVector{OrbitMeanElementsMessage}; file_type::Symbol = :xml
)
    # Check if the messages contain all fields required for writing.
    foreach(_omm_check_writable, vomm)

    # Write the messages using the desired file type.
    file_type == :xml && return _xml_omm__write(io, vomm)
    file_type == :kvn && return _kvn_omm__write(io, vomm)

    return throw(ArgumentError("Unsupported file type: $file_type."))
end

function write_omm(
    file::AbstractString,
    omm::Union{OrbitMeanElementsMessage, AbstractVector{OrbitMeanElementsMessage}};
    file_type::Symbol = :auto,
)
    if file_type == :auto
        file_type = endswith(lowercase(file), ".kvn") ? :kvn : :xml
    end

    open(file, "w") do io
        return write_omm(io, omm; file_type)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _omm_check_writable(omm::OrbitMeanElementsMessage) -> Nothing

Check if `omm` contains all fields required to write an OMM 3.0 output, throwing an
`ArgumentError` otherwise.

This function is format-agnostic so that every supported file type is validated by the same
rules.
"""
function _omm_check_writable(omm::OrbitMeanElementsMessage)
    isnothing(omm.header.creation_date) &&
        throw(ArgumentError("Cannot write OMM 3.0 without a creation date."))

    isempty(omm.header.originator) &&
        throw(ArgumentError("Cannot write OMM 3.0 without an originator."))

    return nothing
end
