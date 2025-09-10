## Description #############################################################################
#
# Parse Orbit Data Messages.
#
############################################################################################

export parse_odm

"""
    parse_odm(filepath::String, T::Type = Float64) -> Union{Nothing, OrbitDataMessage{T}, Vector{OrbitDataMessage{T}}}

Parse an Orbit Data Message (ODM) file in the path `filepath` and return the parsed
message(s). The file format must be XML.

    parse_odm(xml::LazyNodes, T::Type = Float64) -> Union{Nothing, OrbitDataMessage{T}, Vector{OrbitDataMessage{T}}}

Parse an Orbit Data Message (ODM) file in the `LazyNode` `xml` and return the parsed
message(s).

If the XML contains a single message, a single instance of type `OrbitDataMessage{T}` is
returned. If the file contains multiple messages, *i.e.* it is a Navigation Data Message
(NDM), a vector of instances is returned.

The floating point type for the messages can be specified with the type parameter `T`.
"""
function parse_odm(filepath::String, T::Type = Float64)
    # Open the XML file.
    xml = read(filepath, LazyNode)
    return parse_odm(xml, T)
end

function parse_odm(xml::LazyNode, T::Type = Float64)
    # Get the document root node.
    root_node = children(xml)[end]

    # Process the root node.
    t = tag(root_node)

    if t == "opm"
        @warn "We do not support Orbit Parameter Messages (OPM) yet."
    elseif t == "omm"
        return _parse_omm(root_node, T)
    elseif t == "oem"
        @warn "We do not support Orbit Ephemeris Messages (OEM) yet."
    elseif t == "ocm"
        @warn "We do not support Orbit Comprehensive Messages (OCM) yet."
    elseif t == "ndm"
        return _parse_ndm(root_node, T)
    else
        throw(ArgumentError("The root tag `$t` is not recognized."))
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _parse_ndm(xml::LazyNode, T::Type) -> Vector{OrbitDataMessage{T}}

Parse a Navigation Data Message (NDM) from a `LazyNode` `xml` and return a vector of Orbit
Data Messages (ODM).

The floating point type for the messages will be `T`.
"""
function _parse_ndm(xml::LazyNode, T::Type)
    messages = OrbitDataMessage{T}[]

    for node in children(xml)
        tag(node) == "omm" && push!(messages, _parse_omm(node, T))
    end

    return messages
end
