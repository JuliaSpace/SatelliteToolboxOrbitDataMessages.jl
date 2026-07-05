## Description #############################################################################
#
# Parse Orbit Data Messages.
#
############################################################################################

export parse_odm

"""
    parse_odm(str::String) -> Union{Nothing, Vector{OrbitDataMessage}}

Parse an Orbit Data Message (ODM) from the string `str`, which must contain a complete XML
document, and return the parsed message(s).

    parse_odm(xml::LazyNode) -> Union{Nothing, Vector{OrbitDataMessage}}

Parse an Orbit Data Message (ODM) from the `LazyNode` `xml` and return the parsed
message(s).

The return value is always a `Vector{OrbitDataMessage}`: a single-element vector for a
stand-alone message, or a multi-element vector for a Navigation Data Message (NDM) wrapping
multiple messages. If the root tag is not recognized, `nothing` is returned. If the NDM
does not contain any OMM, an empty vector is returned.
"""
function parse_odm(str::String)
    # Open the XML file.
    xml = parse(str, LazyNode)
    return parse_odm(xml)
end

function parse_odm(xml::LazyNode)
    # Get the document root node.
    root_node = children(xml)[end]

    # Process the root node.
    t = tag(root_node)

    if t == "opm"
        @warn "We do not support Orbit Parameter Messages (OPM) yet."
    elseif t == "omm"
        return OrbitDataMessage[_parse_omm(root_node)]
    elseif t == "oem"
        @warn "We do not support Orbit Ephemeris Messages (OEM) yet."
    elseif t == "ocm"
        @warn "We do not support Orbit Comprehensive Messages (OCM) yet."
    elseif t == "ndm"
        return _parse_ndm(root_node)
    else
        throw(ArgumentError("The root tag `$t` is not recognized."))
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _parse_ndm(xml::LazyNode) -> Vector{OrbitDataMessage}

Parse a Navigation Data Message (NDM) from a `LazyNode` `xml` and return a vector of Orbit
Data Messages (ODM).
"""
function _parse_ndm(xml::LazyNode)
    messages = OrbitDataMessage[]

    for node in children(xml)
        tag(node) == "omm" && push!(messages, _parse_omm(node))
    end

    return messages
end
