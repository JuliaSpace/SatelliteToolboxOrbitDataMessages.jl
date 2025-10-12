## Description #############################################################################
#
# Functions to write Orbit Data Messages (ODM).
#
############################################################################################

export write_odm

"""
    write_odm(io::IO, odm::OrbitDataMessage) -> Nothing

Write the given `odm` to the provided `io` stream in XML format.

    write_odm(io::IO, vodm::AbstractVector{T}) where T<:OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the provided `io` stream in XML
format.
"""
function write_odm(io::IO, odm::OrbitDataMessage)
    doc = XML.Element("ndm")

    doc["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    doc["xsi:noNamespaceSchemaLocation"] =
        "https://sanaregistry.org/files/ndmxml_unqualified/ndmxml-4.0.0-master-4.0.xsd"

    if odm isa OrbitMeanElementsMessage
        omm = _omm_to_xml(odm)
        push!(doc, omm)
    end

    XML.write(io, doc)
    return nothing
end

function write_odm(io::IO, vodm::AbstractVector{T}) where T<:OrbitDataMessage
    doc = XML.Element("ndm")

    doc["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    doc["xsi:noNamespaceSchemaLocation"] =
        "https://sanaregistry.org/r/ndmxml_unqualified/ndmxml-3.0.0-master-3.0.xsd"

    for odm in vodm
        if odm isa OrbitMeanElementsMessage
            omm = _omm_to_xml(odm)
            push!(doc, omm)
        end
    end

    XML.write(io, doc)
    return nothing
end
