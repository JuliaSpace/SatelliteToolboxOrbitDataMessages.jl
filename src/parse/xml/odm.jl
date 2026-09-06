## Description #############################################################################
#
# Parse Orbit Data Messages (ODM) using XML input.
#
############################################################################################

# Tags of the ODM message types defined by the CCSDS 502.0-B-3 standard.
const _XML_ODM__TAGS = ("omm", "opm", "oem", "ocm")

"""
    _xml_odm__parse(str::AbstractString) -> Vector{OrbitDataMessage}

Parse the Orbit Data Messages (ODM) in the XML input in `str`, returning a vector with the
parsed messages.

The document can be a stand-alone message or a Navigation Data Message (NDM) wrapping
multiple messages. Unsupported message types (OPM, OEM, OCM) are skipped with a warning. If
the root tag is not recognized, an `OdmParseError` is thrown.
"""
function _xml_odm__parse(str::AbstractString)
    # Open the XML file.
    xml = XML.Cursor(String(str))

    # Get the document root node.
    root_node = next!(xml)
    while !isnothing(root_node) && nodetype(root_node) !== Element
        root_node = next!(xml)
    end
    isnothing(root_node) && throw(OdmParseError("The XML document has no root element."))

    # Process the root node.
    _xml_omm__tag_is(root_node, "ndm") && return _xml_odm__parse_ndm(root_node)

    i = _xml_odm__message_index(root_node)

    isnothing(i) && throw(
        OdmParseError("The root tag `$(tag(root_node))` is not recognized."),
    )

    message = _xml_odm__parse_message(Val(Symbol(_XML_ODM__TAGS[i])), root_node)

    return isnothing(message) ? OrbitDataMessage[] : OrbitDataMessage[message]
end

"""
    _xml_odm__message_index(node::XML.Cursor) -> Union{Nothing, Int}

Return the index in `_XML_ODM__TAGS` of the ODM message type whose tag matches the tag of
`node` ignoring the ASCII case, or `nothing` if `node` is not an ODM message.
"""
function _xml_odm__message_index(node::XML.Cursor)
    node_tag = tag(node)
    isnothing(node_tag) && return nothing
    return findfirst(t -> _ascii_iequal(t, node_tag), _XML_ODM__TAGS)
end

"""
    _xml_odm__parse_message(::Val{tag}, xml::Cursor) -> Union{Nothing, OrbitDataMessage}

Parse the ODM message with the root `tag` at the current position of the `Cursor` `xml`,
dispatching on `Val(tag)`, and return the parsed message. Message types that are not
supported yet emit a warning and return `nothing`.

To add support for a new message type, define a method for the corresponding tag, e.g.
`_xml_odm__parse_message(::Val{:opm}, xml::XML.Cursor)`, returning the assembled message.
"""
function _xml_odm__parse_message(::Val{:omm}, xml::XML.Cursor)
    return _omm_assemble(_xml_omm__parse_element(xml))
end

for (tag, name) in (
    :opm => "Orbit Parameter Messages (OPM)",
    :oem => "Orbit Ephemeris Messages (OEM)",
    :ocm => "Orbit Comprehensive Messages (OCM)",
)
    @eval function _xml_odm__parse_message(::Val{$(QuoteNode(tag))}, xml::XML.Cursor)
        @warn $("We do not support $name yet.")

        # Skip the whole subtree so that the caller does not walk its tokens.
        skip_element!(xml)

        return nothing
    end
end

"""
    _xml_odm__parse_ndm(xml::Cursor) -> Vector{OrbitDataMessage}

Parse a Navigation Data Message (NDM) at the `Cursor` `xml`, returning a vector with the
parsed wrapped messages.
"""
function _xml_odm__parse_ndm(xml::XML.Cursor)
    messages = OrbitDataMessage[]

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        i = _xml_odm__message_index(node)
        isnothing(i) && continue
        message = _xml_odm__parse_message(Val(Symbol(_XML_ODM__TAGS[i])), node)
        isnothing(message) || push!(messages, message)
    end

    return messages
end
