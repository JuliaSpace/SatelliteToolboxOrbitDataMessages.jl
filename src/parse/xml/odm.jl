## Description #############################################################################
#
# Parse Orbit Data Messages (ODM) using XML input.
#
############################################################################################

# Tags of the ODM message types defined by the CCSDS 502.0-B-3 standard.
const _XML_ODM__TAGS = ("omm", "opm", "oem", "ocm")

"""
    _xml_odm__parse(xml::Cursor, strict::Bool) -> Vector{NamedTuple}

Parse the Orbit Data Messages (ODM) in the XML document at the `Cursor` `xml`, returning a
vector of containers `(; type, message)`, where `type` is the `Symbol` of the message type
(e.g. `:omm`) and `message` is the container with the raw field values of that message.

The document can be a stand-alone message or a Navigation Data Message (NDM) wrapping
multiple messages. Unsupported message types (OPM, OEM, OCM) are skipped with a warning.
If the root tag is not recognized, an `ArgumentError` is thrown.
"""
function _xml_odm__parse(xml::XML.Cursor, strict::Bool)
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

    parsed_message = _xml_odm__parse_message(Val(Symbol(t)), root_node, strict)

    return isnothing(parsed_message) ? NamedTuple[] : NamedTuple[parsed_message]
end

"""
    _xml_odm__parse_message(::Val{tag}, xml::Cursor, strict::Bool) -> Union{Nothing, NamedTuple}

Parse the ODM message with the root `tag` at the current position of the `Cursor` `xml`,
dispatching on `Val(tag)`, and return the container `(; type, message)` with the raw field
values. Message types that are not supported yet emit a warning and return `nothing`.

To add support for a new message type, define a method for the corresponding tag, e.g.
`_xml_odm__parse_message(::Val{:opm}, xml::XML.Cursor, strict::Bool)`.
"""
_xml_odm__parse_message(::Val{:omm}, xml::XML.Cursor, strict::Bool) =
    (; type = :omm, message = _xml_omm__parse_element(xml, strict))

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
    _xml_odm__parse_ndm(xml::Cursor, strict::Bool) -> Vector{NamedTuple}

Parse a Navigation Data Message (NDM) at the `Cursor` `xml`, returning a vector of
containers `(; type, message)` with the raw field values of the wrapped messages.
"""
function _xml_odm__parse_ndm(xml::XML.Cursor, strict::Bool)
    parsed_messages = NamedTuple[]

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        t = _xml_omm__tag(node, strict)
        t in _XML_ODM__TAGS || continue
        parsed_message = _xml_odm__parse_message(Val(Symbol(t)), node, strict)
        isnothing(parsed_message) || push!(parsed_messages, parsed_message)
    end

    return parsed_messages
end
