## Description #############################################################################
#
# Write Orbit Data Messages (ODM) using XML output.
#
############################################################################################

"""
    _xml_odm__write(io::IO, vodm::AbstractVector{T}) where T <: OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the provided `io` stream as a
Navigation Data Message (NDM) XML document.
"""
function _xml_odm__write(io::IO, vodm::AbstractVector{T}) where {T <: OrbitDataMessage}
    doc = XML.Document()

    decl = XML.Declaration(; version = "1.0", encoding = "UTF-8")
    push!(doc, decl)

    root = XML.Element(
        "ndm";
        var"xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance",
        var"xsi:noNamespaceSchemaLocation" =
            "https://sanaregistry.org/files/ndmxml_unqualified/ndmxml-4.0.0-master-4.0.xsd",
    )
    push!(doc, root)

    for odm in vodm
        element = _xml_odm__write_element(odm)
        isnothing(element) || push!(root, element)
    end

    XML.write(io, doc)

    return nothing
end

"""
    _xml_odm__write_element(odm::OrbitDataMessage) -> Union{Nothing, XML.Node}

Convert `odm` to an XML element suitable for embedding in an NDM document. Message types
that cannot be written yet emit a warning and return `nothing`.

To add support for a new message type, define a method for the corresponding concrete
type.
"""
_xml_odm__write_element(omm::OrbitMeanElementsMessage) = _xml_omm__write_element(omm)

function _xml_odm__write_element(odm::OrbitDataMessage)
    @warn "Skipping unsupported message of type $(typeof(odm)) during ODM writing."
    return nothing
end
