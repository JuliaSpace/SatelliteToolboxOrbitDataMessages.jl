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

    write_odm(file::AbstractString, odm::OrbitDataMessage) -> Nothing

Write the given `odm` to the file at `file` in XML format, overwriting its contents.

    write_odm(file::AbstractString, vodm::AbstractVector{T}) where T<:OrbitDataMessage -> Nothing

Write the set of Orbit Data Messages in the vector `vodm` to the file at `file` in XML
format, overwriting its contents.
"""
write_odm(io::IO, odm::OrbitDataMessage) = write_odm(io, [odm])

function write_odm(io::IO, vodm::AbstractVector{T}) where T <: OrbitDataMessage
    doc = XML.Document()

    decl = XML.Declaration(; version = "1.0", encoding = "UTF-8")
    push!(doc, decl)

    root = XML.Element(
        "ndm";
        var"xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance",
        var"xsi:noNamespaceSchemaLocation" =
            "https://sanaregistry.org/files/ndmxml_unqualified/ndmxml-4.0.0-master-4.0.xsd"
    )
    push!(doc, root)

    for odm in vodm
        element = _odm_to_xml_element(odm)
        isnothing(element) || push!(root, element)
    end

    XML.write(io, doc)
    return nothing
end

function write_odm(file::AbstractString, odm::OrbitDataMessage)
    open(file, "w") do io
        write_odm(io, odm)
    end

    return nothing
end

function write_odm(file::AbstractString, vodm::AbstractVector{T}) where T<:OrbitDataMessage
    open(file, "w") do io
        write_odm(io, vodm)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _odm_to_xml_element(odm::OrbitDataMessage) -> Union{Nothing, XML.Node}

Convert `odm` to an XML element suitable for embedding in an NDM document. Message types
that cannot be written yet emit a warning and return `nothing`.

To add support for a new message type, define a method for the corresponding concrete
type.
"""
_odm_to_xml_element(omm::OrbitMeanElementsMessage) = _omm_to_xml(omm, Val(false))

function _odm_to_xml_element(odm::OrbitDataMessage)
    @warn "Skipping unsupported message of type $(typeof(odm)) during ODM writing."
    return nothing
end
