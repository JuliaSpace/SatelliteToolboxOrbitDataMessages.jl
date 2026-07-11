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

    parse_odm(xml::Cursor; kwargs...) -> Vector{OrbitDataMessage}

Parse an Orbit Data Message (ODM) from the `Cursor` `xml` and return the parsed
message(s).

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
    return parse_odm(xml; strict)
end

function parse_odm(xml::XML.Cursor; strict::Bool = true)
    # Get the document root node.
    root_node = next!(xml)
    while !isnothing(root_node) && nodetype(root_node) !== Element
        root_node = next!(xml)
    end
    isnothing(root_node) && throw(ArgumentError("The XML document has no root element."))

    # Process the root node.
    t = _omm_tag(root_node, strict)

    if t == "opm"
        @warn "We do not support Orbit Parameter Messages (OPM) yet."
        return OrbitDataMessage[]
    elseif t == "omm"
        return OrbitDataMessage[_parse_omm(root_node, strict)]
    elseif t == "oem"
        @warn "We do not support Orbit Ephemeris Messages (OEM) yet."
        return OrbitDataMessage[]
    elseif t == "ocm"
        @warn "We do not support Orbit Comprehensive Messages (OCM) yet."
        return OrbitDataMessage[]
    elseif t == "ndm"
        return _parse_ndm(root_node, strict)
    else
        return throw(ArgumentError("The root tag `$t` is not recognized."))
    end
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _parse_ndm(xml::Cursor, strict::Bool) -> Vector{OrbitDataMessage}

Parse a Navigation Data Message (NDM) from a `Cursor` `xml` and return a vector of Orbit
Data Messages (ODM).
"""
function _parse_ndm(xml::XML.Cursor, strict::Bool)
    messages = OrbitDataMessage[]

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)

        if lt == "omm"
            push!(messages, _parse_omm(node, strict))
        elseif lt == "opm"
            @warn "We do not support Orbit Parameter Messages (OPM) yet."
        elseif lt == "oem"
            @warn "We do not support Orbit Ephemeris Messages (OEM) yet."
        elseif lt == "ocm"
            @warn "We do not support Orbit Comprehensive Messages (OCM) yet."
        end
    end

    return messages
end
