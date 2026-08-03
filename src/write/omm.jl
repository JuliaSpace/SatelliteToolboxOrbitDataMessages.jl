## Description #############################################################################
#
# Functions to write Orbit Mean-Elements Message (OMM) files.
#
############################################################################################

export write_omm

"""
    write_omm(io::IO, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the provided `io` stream in XML format.

    write_omm(file::AbstractString, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the file at `file` in XML format, overwriting its contents.
"""
function write_omm(io::IO, omm::OrbitMeanElementsMessage)
    # Check if the message contains all fields required for writing.
    _omm_check_writable(omm)

    # Write the message using the desired file type.
    _xml_omm__write(io, omm)

    return nothing
end

function write_omm(file::AbstractString, omm::OrbitMeanElementsMessage)
    open(file, "w") do io
        write_omm(io, omm)
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

This function is format-agnostic so that every supported file type is validated by the
same rules.
"""
function _omm_check_writable(omm::OrbitMeanElementsMessage)
    isnothing(omm.header.creation_date) && throw(ArgumentError(
        "Cannot write OMM 3.0 without a creation date."
    ))

    isempty(omm.header.originator) && throw(ArgumentError(
        "Cannot write OMM 3.0 without an originator."
    ))

    return nothing
end
