## Description #############################################################################
#
# Parse Orbit Data Messages (ODM) using XML input.
#
############################################################################################

# Tags of the ODM message types defined by the CCSDS 502.0-B-3 standard.
const _XML_ODM__TAGS = ("omm", "opm", "oem", "ocm")

"""
    _xml_odm__parse(str::AbstractString, strict::Bool) -> Vector{OrbitDataMessage}

Parse the Orbit Data Messages (ODM) in the XML input in `str`, returning a vector with the
parsed messages.

The document can be a stand-alone message or a Navigation Data Message (NDM) wrapping
multiple messages. Unsupported message types (OPM, OEM, OCM) are skipped with a warning.
If the root tag is not recognized, an `ArgumentError` is thrown.
"""
function _xml_odm__parse(str::AbstractString, strict::Bool)
    # Open the XML file.
    xml = XML.Cursor(String(str))

    # Get the document root node.
    root_node = next!(xml)
    while !isnothing(root_node) && nodetype(root_node) !== Element
        root_node = next!(xml)
    end
    isnothing(root_node) && throw(ArgumentError("The XML document has no root element."))

    # Process the root node.
    t = _xml_omm__tag(root_node, strict)

    t == "ndm" && return _xml_odm__parse_ndm(root_node, strict)

    t in _XML_ODM__TAGS || throw(ArgumentError("The root tag `$t` is not recognized."))

    message = _xml_odm__parse_message(Val(Symbol(t)), root_node, strict)

    return isnothing(message) ? OrbitDataMessage[] : OrbitDataMessage[message]
end

"""
    _xml_odm__parse_message(::Val{tag}, xml::Cursor, strict::Bool) -> Union{Nothing, OrbitDataMessage}

Parse the ODM message with the root `tag` at the current position of the `Cursor` `xml`,
dispatching on `Val(tag)`, and return the parsed message. Message types that are not
supported yet emit a warning and return `nothing`.

To add support for a new message type, define a method for the corresponding tag, e.g.
`_xml_odm__parse_message(::Val{:opm}, xml::XML.Cursor, strict::Bool)`, returning the
assembled message.
"""
_xml_odm__parse_message(::Val{:omm}, xml::XML.Cursor, strict::Bool) =
    _omm_assemble(_xml_omm__parse_element(xml, strict))

for (tag, name) in (
    :opm => "Orbit Parameter Messages (OPM)",
    :oem => "Orbit Ephemeris Messages (OEM)",
    :ocm => "Orbit Comprehensive Messages (OCM)",
)
    @eval function _xml_odm__parse_message(::Val{$(QuoteNode(tag))}, ::XML.Cursor, ::Bool)
        @warn $("We do not support $name yet.")
        return nothing
    end
end

"""
    _xml_odm__parse_ndm(xml::Cursor, strict::Bool) -> Vector{OrbitDataMessage}

Parse a Navigation Data Message (NDM) at the `Cursor` `xml`, returning a vector with the
parsed wrapped messages.
"""
function _xml_odm__parse_ndm(xml::XML.Cursor, strict::Bool)
    messages = OrbitDataMessage[]

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        t = _xml_omm__tag(node, strict)
        t in _XML_ODM__TAGS || continue
        message = _xml_odm__parse_message(Val(Symbol(t)), node, strict)
        isnothing(message) || push!(messages, message)
    end

    return messages
end
