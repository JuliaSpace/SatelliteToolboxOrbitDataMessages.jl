## Description #############################################################################
#
# Functions related to XML handling.
#
############################################################################################

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _xml_add_tag!(parent::XML.Node, tag::String, value::Any) -> Nothing

Add a child XML tag to `parent` with the given `tag` name and `value`.
"""
function _xml_add_tag!(parent::XML.Node, tag::String, value::Any)
    isnothing(value) && return nothing
    child = XML.Element(tag)
    push!(child, XML.Text(_xml_render(value)))
    push!(parent, child)
    return nothing
end

"""
    _xml_render(value::T) -> String

Render the given `value` of type `T` as a string suitable for XML.
"""
_xml_render(value::String) = value
_xml_render(value::Any) = string(value)
_xml_render(value::NanoDate) = Dates.format(value, dateformat"yyyy-mm-ddTHH:MM:SS.ssssss")
