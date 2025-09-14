## Description #############################################################################
#
# Parse Orbit Data Messages.
#
############################################################################################

export parse_odm

"""
    parse_odm(str::String) -> Union{Nothing, OrbitDataMessage, Vector{OrbitDataMessage}}

Parse an Orbit Data Message (ODM) string `str` and return the parsed message(s). The input
format must be XML.

    parse_odm(xml::LazyNodes) -> Union{Nothing, OrbitDataMessage, Vector{OrbitDataMessage}}

Parse an Orbit Data Message (ODM) file in the `LazyNode` `xml` and return the parsed
message(s).

If the XML contains a single message, a single instance of type `OrbitDataMessage` is
returned. If the file contains multiple messages, *i.e.* it is a Navigation Data Message
(NDM), a vector of instances is returned.
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
        return _parse_omm(root_node)
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
