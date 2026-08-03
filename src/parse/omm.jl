## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM).
#
############################################################################################

export parse_omm, parse_omms

############################################################################################
#                                     Public Functions                                     #
############################################################################################

"""
    parse_omm(str::AbstractString; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) in the string `str` and return the parsed
message.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omm(str::AbstractString; strict::Bool = true)
    # Open the XML file.
    xml = XML.Cursor(String(str))
    return parse_omm(xml; strict)
end

"""
    parse_omms(str::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) in the string `str` and return the
parsed messages.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omms(str::AbstractString; strict::Bool = true)
    # Open the XML file.
    xml = XML.Cursor(String(str))
    return parse_omms(xml; strict)
end

############################################################################################
#                                         Includes                                         #
############################################################################################

include("./kvn/omm.jl")
include("./xml/omm.jl")
