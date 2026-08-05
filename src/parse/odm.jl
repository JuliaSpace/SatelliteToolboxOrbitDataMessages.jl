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
multiple messages. Unsupported message types (OPM, OEM, OCM) are skipped with a warning;
if no supported message remains, an empty vector is returned. If the root tag is not
recognized, an `ArgumentError` is thrown.

# Keywords

- `strict::Bool`: Select the validation strictness. If `true`, the schema-defined XML tag
    casing is required, empty XML element values are rejected, and the `CREATION_DATE`
    field must be present. If `false`, tags and the OMM `id` attribute value are matched
    case-insensitively, empty XML element values are skipped, and the `CREATION_DATE` may
    be absent.
    (**Default**: `true`)
"""
function parse_odm(str::AbstractString; strict::Bool = true)
    return _xml_odm__parse(str, strict)
end
