## Description #############################################################################
#
# Parse Orbit Data Messages.
#
############################################################################################

export parse_odm

"""
    parse_odm(str::AbstractString; kwargs...) -> Vector{OrbitDataMessage}

Parse an Orbit Data Message (ODM) from the string `str`, which must contain a complete XML
document, and return the parsed message(s).

The return value is always a `Vector{OrbitDataMessage}`: a single-element vector for a
stand-alone message, or a multi-element vector for a Navigation Data Message (NDM) wrapping
multiple messages. Unsupported message types (OPM, OEM, OCM) are skipped with a warning,
returning an empty vector. If the root tag is not recognized, an `ArgumentError` is thrown.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_odm(str::AbstractString; strict::Bool = true)
    # Open the XML file.
    xml = XML.Cursor(String(str))

    # Parse the file, obtaining the containers with the raw field values.
    parsed_messages = _xml_odm__parse(xml, strict)

    # Check the mandatory fields and assemble the messages.
    return OrbitDataMessage[
        _odm_assemble(parsed_message) for parsed_message in parsed_messages
    ]
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _odm_assemble(parsed_odm::NamedTuple) -> OrbitDataMessage

Assemble an Orbit Data Message (ODM) from the container `parsed_odm` returned by a
format-specific parser. The container is a named tuple:

    (; type, message)

where `type` is the `Symbol` of the message type (e.g. `:omm`) and `message` is the
container with the raw field values of that message.

The mandatory fields are validated by the assembler of the corresponding message type before
the message is created.
"""
function _odm_assemble(parsed_odm::NamedTuple)
    parsed_odm.type == :omm && return _omm_assemble(parsed_odm.message)
    throw(ArgumentError("Unsupported ODM message type `$(parsed_odm.type)`."))
end
