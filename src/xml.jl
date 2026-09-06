## Description #############################################################################
#
# Functions related to XML handling.
#
############################################################################################

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _xml__root_element(xml::XML.Cursor) -> XML.Cursor

Advance the `Cursor` `xml` to the root element of the document and return it, throwing an
`OdmParseError` if the document has no element.
"""
function _xml__root_element(xml::XML.Cursor)
    root_node = next!(xml)

    while !isnothing(root_node) && nodetype(root_node) !== Element
        root_node = next!(xml)
    end

    isnothing(root_node) && throw(OdmParseError("The XML document has no root element."))

    return root_node
end

"""
    _xml_add_tag!(parent::XML.Node, tag::String, value::Any) -> Nothing

Add a child XML tag to `parent` with the given `tag` name and `value`, rendered with
[`_ndm_render_value`](@ref). If `value` is `nothing`, no tag is added.
"""
function _xml_add_tag!(parent::XML.Node, tag::String, value::Any)
    isnothing(value) && return nothing
    child = XML.Element(tag)
    push!(child, XML.Text(_ndm_render_value(value)))
    push!(parent, child)
    return nothing
end
