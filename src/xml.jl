## Description #############################################################################
#
# Functions related to XML handling.
#
############################################################################################

############################################################################################
#                                        Constants                                         #
############################################################################################

# XML declaration written at the beginning of every document.
const _XML__DECLARATION = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

# Schema attributes of the root element of every document.
const _XML__SCHEMA_ATTRIBUTES =
    "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " *
    "xsi:noNamespaceSchemaLocation=\"https://sanaregistry.org/files/ndmxml_unqualified/" *
    "ndmxml-4.0.0-master-4.0.xsd\""

# Number of spaces per indentation level in the written documents.
const _XML__INDENT_WIDTH = 2

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

# == Writing ===============================================================================

# The documents are written directly to the output stream instead of building an XML tree
# first, which avoids allocating a node per element.

"""
    _xml__escape(io::IO, str::AbstractString) -> Nothing
    _xml__escape(io::IO, c::Char) -> Nothing

Print `str` (or the character `c`) to `io`, replacing the characters that are not allowed
in XML text and attribute values by the corresponding entities.
"""
function _xml__escape(io::IO, str::AbstractString)
    for c in str
        _xml__escape(io, c)
    end

    return nothing
end

function _xml__escape(io::IO, c::Char)
    if c == '&'
        print(io, "&amp;")
    elseif c == '<'
        print(io, "&lt;")
    elseif c == '>'
        print(io, "&gt;")
    elseif c == '"'
        print(io, "&quot;")
    else
        print(io, c)
    end

    return nothing
end

"""
    _xml__print_text(io::IO, value::Any) -> Nothing

Print `value` to `io` as the text of an XML element. Strings and characters are escaped
(see [`_xml__escape`](@ref)), whereas the other types are rendered with
[`_ndm_print_value`](@ref), which never yields characters that require escaping.
"""
_xml__print_text(io::IO, value::Union{AbstractString, Char}) = _xml__escape(io, value)
_xml__print_text(io::IO, value::Any) = _ndm_print_value(io, value)

"""
    _xml__indent(io::IO, level::Int) -> Nothing

Print the indentation of the given `level` to `io`.
"""
function _xml__indent(io::IO, level::Int)
    for _ in 1:(_XML__INDENT_WIDTH * level)
        write(io, UInt8(' '))
    end

    return nothing
end

"""
    _xml__open_tag(io::IO, level::Int, tag::String) -> Nothing

Print the opening `tag` at the indentation `level` to `io`, followed by a line break.
"""
function _xml__open_tag(io::IO, level::Int, tag::String)
    _xml__indent(io, level)
    print(io, '<', tag, ">\n")
    return nothing
end

"""
    _xml__close_tag(io::IO, level::Int, tag::String) -> Nothing

Print the closing `tag` at the indentation `level` to `io`, followed by a line break.
"""
function _xml__close_tag(io::IO, level::Int, tag::String)
    _xml__indent(io, level)
    print(io, "</", tag, ">\n")
    return nothing
end

"""
    _xml__write_element(io::IO, level::Int, tag::String, value::Any) -> Nothing

Print the element `<tag>value</tag>` at the indentation `level` to `io`, followed by a
line break. The `value` is rendered with [`_xml__print_text`](@ref). If `value` is
`nothing`, no element is written.
"""
function _xml__write_element(io::IO, level::Int, tag::String, value::Any)
    isnothing(value) && return nothing

    _xml__indent(io, level)
    print(io, '<', tag, '>')
    _xml__print_text(io, value)
    print(io, "</", tag, ">\n")

    return nothing
end
