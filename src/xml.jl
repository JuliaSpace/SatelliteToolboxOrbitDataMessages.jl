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
