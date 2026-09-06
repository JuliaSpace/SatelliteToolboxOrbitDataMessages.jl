## Description #############################################################################
#
# Parse a set of Orbit Mean-Elements Messages (OMM) using XML input.
#
############################################################################################

"""
    _xml_omms__parse(str::AbstractString, strict::Bool) -> Vector{OrbitMeanElementsMessage}

Parse the Orbit Mean-Elements Messages (OMM) in the XML input in `str`, returning a vector
with the parsed messages.

The document can be a stand-alone message or a Navigation Data Message (NDM) wrapping
multiple messages. Messages that are not OMMs are skipped, and unsupported message types
(OPM, OEM, OCM) additionally emit a warning. If the root tag is not recognized, an
`OdmParseError` is thrown.
"""
function _xml_omms__parse(str::AbstractString, strict::Bool)
    messages = _xml_odm__parse(str, strict)

    # Keep only the OMM messages, skipping the other types.
    return OrbitMeanElementsMessage[
        message for message in messages if message isa OrbitMeanElementsMessage
    ]
end
