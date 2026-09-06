## Description #############################################################################
#
# Parse Orbit Data Messages.
#
############################################################################################

export parse_odm

"""
    parse_odm(str::AbstractString) -> Vector{OrbitDataMessage}

Parse an Orbit Data Message (ODM) from the string `str`, which must contain a complete XML
document, and return the parsed message(s).

The return value is always a `Vector{OrbitDataMessage}`: a single-element vector for a
stand-alone message, or a multi-element vector for a Navigation Data Message (NDM) wrapping
multiple messages. Unsupported message types (OPM, OEM, OCM) are skipped with a warning;
if no supported message remains, an empty vector is returned. If the root tag is not
recognized or the input is malformed, an [`OdmParseError`](@ref) is thrown. The XML tags
are matched ignoring the case (see [`parse_omm`](@ref) for the other accommodated
deviations).
"""
function parse_odm(str::AbstractString)
    return _xml_odm__parse(str)
end
