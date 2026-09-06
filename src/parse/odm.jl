## Description #############################################################################
#
# Parse Orbit Data Messages.
#
############################################################################################

export parse_odm

"""
    parse_odm(str::AbstractString; kwargs...) -> Vector{OrbitDataMessage}

Parse the Orbit Data Messages (ODM) in the string `str` and return the parsed message(s).

The return value is always a `Vector{OrbitDataMessage}`. For XML input, the document can be
a stand-alone message, yielding a single-element vector, or a Navigation Data Message (NDM)
wrapping multiple messages. For KVN input, the messages are written sequentially, each one
starting at its version keyword. Unsupported message types (OPM, OEM, OCM) are skipped
with a warning; if no supported message remains, an empty vector is returned. If the root
tag is not recognized or the input is malformed, an [`OdmParseError`](@ref) is thrown. See
[`parse_omm`](@ref) for the accommodated deviations from the standard.

# Keywords

- `format::Symbol`: The input format. If `:auto`, the format is inferred from the content.
    It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
"""
function parse_odm(str::AbstractString; format::Symbol = :auto)
    str, format = _odm_prepare_input(str, format)

    format == :xml && return _xml_odm__parse(str)

    return _kvn_odm__parse(str)
end
