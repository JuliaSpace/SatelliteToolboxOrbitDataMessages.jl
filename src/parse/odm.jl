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
    t = _xml_omm__tag(root_node, strict)

    t == "ndm" && return _parse_ndm(root_node, strict)

    _is_odm_tag(t) || throw(ArgumentError("The root tag `$t` is not recognized."))

    message = _parse_message(Val(Symbol(t)), root_node, strict)

    return isnothing(message) ? OrbitDataMessage[] : OrbitDataMessage[message]
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# Tags of the ODM message types defined by the CCSDS 502.0-B-3 standard.
const _ODM_TAGS = ("omm", "opm", "oem", "ocm")

"""
    _is_odm_tag(tag::AbstractString) -> Bool

Return whether `tag` is an ODM message tag defined by the CCSDS 502.0-B-3 standard.
"""
_is_odm_tag(tag::AbstractString) = tag in _ODM_TAGS

"""
    _parse_message(::Val{tag}, xml::Cursor, strict::Bool) -> Union{Nothing, OrbitDataMessage}

Parse the ODM message with the root `tag` at the current position of the `Cursor` `xml`,
dispatching on `Val(tag)`. Message types that are not supported yet emit a warning and
return `nothing`.

To add support for a new message type, define a method for the corresponding tag, e.g.
`_parse_message(::Val{:opm}, xml::XML.Cursor, strict::Bool)`.
"""
_parse_message(::Val{:omm}, xml::XML.Cursor, strict::Bool) = _xml_omm__parse(xml, strict)

for (tag, name) in (
    :opm => "Orbit Parameter Message (OPM) files",
    :oem => "Orbit Ephemeris Message (OEM) files",
    :ocm => "Orbit Comprehensive Message (OCM) files",
)
    @eval function _parse_message(::Val{$(QuoteNode(tag))}, xml::XML.Cursor, ::Bool)
        @warn $("We do not support $name yet.")
        # Consume the unsupported element so that the caller does not tokenize its entire
        # subtree node-by-node.
        skip_element!(xml)
        return nothing
    end
end

"""
    _parse_ndm(xml::Cursor, strict::Bool) -> Vector{OrbitDataMessage}

Parse a Navigation Data Message (NDM) from a `Cursor` `xml` and return a vector of Orbit
Data Messages (ODM).
"""
function _parse_ndm(xml::XML.Cursor, strict::Bool)
    messages = OrbitDataMessage[]

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        t = _xml_omm__tag(node, strict)

        if !_is_odm_tag(t)
            # Consume the unrecognized element so that its subtree is not tokenized
            # node-by-node.
            skip_element!(node)
            continue
        end

        message = _parse_message(Val(Symbol(t)), node, strict)
        isnothing(message) || push!(messages, message)
    end

    return messages
end
