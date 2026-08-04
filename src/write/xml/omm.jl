## Description #############################################################################
#
# Write Orbit Mean-Elements Messages (OMM) using XML output.
#
############################################################################################

"""
    _xml_omm__write(io::IO, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the provided `io` stream as a stand-alone XML document. Hence,
the XML declaration is included.

The written version is always `3.0`, regardless of the version stored in the `omm`. This
matches the schema against which the output is validated.

    _xml_omm__write(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage}) -> Nothing

Write the set of Orbit Mean-Elements Messages in the vector `vomm` to the provided `io`
stream as a Navigation Data Message (NDM) XML document.
"""
function _xml_omm__write(io::IO, omm::OrbitMeanElementsMessage)
    doc = XML.Document()

    # XML Declaration.
    decl = XML.Declaration(; version = "1.0", encoding = "UTF-8")
    push!(doc, decl)

    # Our XML is compatible with version 3.
    root = XML.Element(
        "omm";
        id = "CCSDS_OMM_VERS",
        version = "3.0",
        var"xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance",
        var"xsi:noNamespaceSchemaLocation" = "https://sanaregistry.org/files/ndmxml_unqualified/ndmxml-4.0.0-master-4.0.xsd",
    )

    push!(doc, root)

    _xml_omm__add_tags!(root, omm)

    XML.write(io, doc)

    return nothing
end

function _xml_omm__write(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage})
    # A set of messages is written as an NDM document, which is already implemented by the
    # ODM writer.
    return _xml_odm__write(io, vomm)
end

"""
    _xml_omm__write_element(omm::OrbitMeanElementsMessage) -> XML.Node

Convert the given `omm` to an XML element suitable for embedding within another XML
document (e.g. an NDM). Hence, the XML declaration is omitted.

The written version is always `3.0`, regardless of the version stored in the `omm`. This
matches the schema against which the output is validated.
"""
function _xml_omm__write_element(omm::OrbitMeanElementsMessage)
    element = XML.Element("omm"; id = "CCSDS_OMM_VERS", version = "3.0")

    _xml_omm__add_tags!(element, omm)

    return element
end

"""
    _xml_omm__add_tags!(parent::XML.Node, omm::OrbitMeanElementsMessage) -> Nothing

Add the OMM tags from the given `omm` message to the `parent` XML node.

The tags of each section are obtained automatically from the corresponding keyword
mapping (see `_xml_omm__add_section_tags!`), so the output follows the keyword order
defined by the CCSDS 502.0-B-3 standard.
"""
function _xml_omm__add_tags!(parent::XML.Node, omm::OrbitMeanElementsMessage)
    data = omm.data

    # == Header ============================================================================

    header_node = XML.Element("header")
    push!(parent, header_node)

    _xml_omm__add_section_tags!(
        header_node, omm.header, _OMM_HEADER_KEYWORD_TO_FIELD, omm.header.comments
    )

    # == Body ==============================================================================

    body_node = XML.Element("body")
    push!(parent, body_node)

    segment_node = XML.Element("segment")
    push!(body_node, segment_node)

    # -- Metadata --------------------------------------------------------------------------

    metadata_node = XML.Element("metadata")
    push!(segment_node, metadata_node)

    _xml_omm__add_section_tags!(
        metadata_node, omm.metadata, _OMM_METADATA_KEYWORD_TO_FIELD, omm.metadata.comments
    )

    # -- Data ------------------------------------------------------------------------------

    data_node = XML.Element("data")
    push!(segment_node, data_node)

    foreach(comment -> _xml_add_tag!(data_node, "COMMENT", comment), data.comments)

    # .. Mean Keplerian Elements ...........................................................

    mean_elements_node = XML.Element("meanElements")
    push!(data_node, mean_elements_node)

    _xml_omm__add_section_tags!(
        mean_elements_node,
        data,
        _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD,
        data.mean_elements_comments,
    )

    # .. Spacecraft Parameters .............................................................

    # The optional sections are only added to the document if they contain any tag.
    spacecraft_parameters_node = XML.Element("spacecraftParameters")

    _xml_omm__add_section_tags!(
        spacecraft_parameters_node,
        data,
        _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
        data.spacecraft_parameters_comments,
    )

    isempty(children(spacecraft_parameters_node)) ||
        push!(data_node, spacecraft_parameters_node)

    # .. TLE Related Parameters ............................................................

    tle_parameters_node = XML.Element("tleParameters")

    _xml_omm__add_section_tags!(
        tle_parameters_node,
        data,
        _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD,
        data.tle_parameters_comments,
    )

    isempty(children(tle_parameters_node)) || push!(data_node, tle_parameters_node)

    # .. Covariance Matrix .................................................................

    if !isnothing(data.covariance_matrix)
        covariance_matrix = data.covariance_matrix
        covariance_matrix_node = XML.Element("covarianceMatrix")

        _xml_omm__add_section_tags!(
            covariance_matrix_node,
            covariance_matrix,
            _OMM_COVARIANCE_KEYWORD_TO_FIELD,
            covariance_matrix.comments,
        )

        push!(data_node, covariance_matrix_node)
    end

    # .. User-Defined Parameters ...........................................................

    if !isnothing(data.user_defined_parameters)
        user_defined_parameters_node = XML.Element("userDefinedParameters")

        for (key, value) in data.user_defined_parameters
            child = XML.Element("USER_DEFINED"; parameter = key)
            push!(child, XML.Text(_ndm_render_value(value)))
            push!(user_defined_parameters_node, child)
        end

        push!(data_node, user_defined_parameters_node)
    end

    return nothing
end

"""
    _xml_omm__add_section_tags!(
        node::XML.Node,
        section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
        mapping::Vector{Pair{String, Symbol}},
        comments::Vector{String}
    ) -> Nothing

Add the tags of the OMM `section` to the XML `node`. The added tags and their fields are
given by `mapping`, whose order is preserved in the output, and the section `comments` are
added before the fields.

Fields whose value is `nothing` are omitted from the output.
"""
function _xml_omm__add_section_tags!(
    node::XML.Node,
    section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
    mapping::Vector{Pair{String, Symbol}},
    comments::Vector{String},
)
    foreach(comment -> _xml_add_tag!(node, "COMMENT", comment), comments)

    for (keyword, field) in mapping
        _xml_add_tag!(node, keyword, getfield(section, field))
    end

    return nothing
end
