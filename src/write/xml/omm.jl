## Description #############################################################################
#
# Write Orbit Mean-Elements Messages (OMM) using XML output.
#
############################################################################################

"""
    _xml_omm__write(io::IO, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the provided `io` stream as a stand-alone XML document. Hence, the
XML declaration is included.

The written version is always `3.0`, regardless of the version stored in the `omm`. This
matches the schema declared in the `xsi:noNamespaceSchemaLocation` attribute.

    _xml_omm__write(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage}) -> Nothing

Write the set of Orbit Mean-Elements Messages in the vector `vomm` to the provided `io`
stream as a Navigation Data Message (NDM) XML document.
"""
function _xml_omm__write(io::IO, omm::OrbitMeanElementsMessage)
    println(io, _XML__DECLARATION)
    _xml_omm__write_element(io, omm, 0; root = true)
    return nothing
end

function _xml_omm__write(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage})
    # A set of messages is written as an NDM document, which is already implemented by the
    # ODM writer.
    return _xml_odm__write(io, vomm)
end

"""
    _xml_omm__write_element(
        io::IO,
        omm::OrbitMeanElementsMessage,
        level::Int;
        root::Bool = false
    ) -> Nothing

Write the given `omm` to the provided `io` stream as an `omm` XML element at the
indentation `level`. If `root` is `true`, the element carries the schema attributes of a
stand-alone document; otherwise, it is suitable for embedding within another XML document
(e.g. an NDM).

The written version is always `3.0`, regardless of the version stored in the `omm`. The
tags of each section are obtained from the corresponding keyword mapping (see
[`_xml_omm__write_section`](@ref)), so the output follows the keyword order defined by the
CCSDS 502.0-B-3 standard.
"""
function _xml_omm__write_element(
    io::IO, omm::OrbitMeanElementsMessage, level::Int; root::Bool = false
)
    data = omm.data

    _xml__indent(io, level)
    print(io, "<omm id=\"CCSDS_OMM_VERS\" version=\"3.0\"")
    root && print(io, ' ', _XML__SCHEMA_ATTRIBUTES)
    print(io, ">\n")

    # == Header ============================================================================

    _xml__open_tag(io, level + 1, "header")

    _xml_omm__write_section(
        io, level + 2, omm.header, _OMM_HEADER_KEYWORD_TO_FIELD, omm.header.comments
    )

    _xml__close_tag(io, level + 1, "header")

    # == Body ==============================================================================

    _xml__open_tag(io, level + 1, "body")
    _xml__open_tag(io, level + 2, "segment")

    # -- Metadata --------------------------------------------------------------------------

    _xml__open_tag(io, level + 3, "metadata")

    _xml_omm__write_section(
        io, level + 4, omm.metadata, _OMM_METADATA_KEYWORD_TO_FIELD, omm.metadata.comments
    )

    _xml__close_tag(io, level + 3, "metadata")

    # -- Data ------------------------------------------------------------------------------

    _xml__open_tag(io, level + 3, "data")

    for comment in data.comments
        _xml__write_element(io, level + 4, "COMMENT", comment)
    end

    # .. Mean Keplerian Elements ...........................................................

    _xml__open_tag(io, level + 4, "meanElements")

    _xml_omm__write_section(
        io,
        level + 5,
        data,
        _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD,
        data.mean_elements_comments,
    )

    _xml__close_tag(io, level + 4, "meanElements")

    # .. Spacecraft Parameters .............................................................

    # The optional sections are only written if they contain any element.
    if !_xml_omm__section_is_empty(
        data,
        _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
        data.spacecraft_parameters_comments,
    )
        _xml__open_tag(io, level + 4, "spacecraftParameters")

        _xml_omm__write_section(
            io,
            level + 5,
            data,
            _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
            data.spacecraft_parameters_comments,
        )

        _xml__close_tag(io, level + 4, "spacecraftParameters")
    end

    # .. TLE Related Parameters ............................................................

    if !_xml_omm__section_is_empty(
        data, _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD, data.tle_parameters_comments
    )
        _xml__open_tag(io, level + 4, "tleParameters")

        _xml_omm__write_section(
            io,
            level + 5,
            data,
            _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD,
            data.tle_parameters_comments,
        )

        _xml__close_tag(io, level + 4, "tleParameters")
    end

    # .. Covariance Matrix .................................................................

    covariance_matrix = data.covariance_matrix

    if !isnothing(covariance_matrix)
        _xml__open_tag(io, level + 4, "covarianceMatrix")

        _xml_omm__write_section(
            io,
            level + 5,
            covariance_matrix,
            _OMM_COVARIANCE_KEYWORD_TO_FIELD,
            covariance_matrix.comments,
        )

        _xml__close_tag(io, level + 4, "covarianceMatrix")
    end

    # .. User-Defined Parameters ...........................................................

    # An empty vector is an absent section, so no empty element is written, which would
    # not satisfy the schema content model.
    if !isempty(data.user_defined_parameters)
        _xml__open_tag(io, level + 4, "userDefinedParameters")

        for (key, value) in data.user_defined_parameters
            _xml__indent(io, level + 5)
            print(io, "<USER_DEFINED parameter=\"")
            _xml__escape(io, key)
            print(io, "\">")
            _xml__escape(io, value)
            print(io, "</USER_DEFINED>\n")
        end

        _xml__close_tag(io, level + 4, "userDefinedParameters")
    end

    _xml__close_tag(io, level + 3, "data")
    _xml__close_tag(io, level + 2, "segment")
    _xml__close_tag(io, level + 1, "body")
    _xml__close_tag(io, level, "omm")

    return nothing
end

"""
    _xml_omm__write_section(
        io::IO,
        level::Int,
        section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
        mapping::Vector{Pair{String, Symbol}},
        comments::Vector{String}
    ) -> Nothing

Write the elements of the OMM `section` to the provided `io` stream at the indentation
`level`. The written tags and their fields are given by `mapping`, whose order is preserved
in the output, and the section `comments` are written before the fields.

Fields whose value is `nothing` are omitted from the output.
"""
function _xml_omm__write_section(
    io::IO,
    level::Int,
    section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
    mapping::Vector{Pair{String, Symbol}},
    comments::Vector{String},
)
    for comment in comments
        _xml__write_element(io, level, "COMMENT", comment)
    end

    for (keyword, field) in mapping
        _xml__write_element(io, level, keyword, getfield(section, field))
    end

    return nothing
end

"""
    _xml_omm__section_is_empty(
        section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
        mapping::Vector{Pair{String, Symbol}},
        comments::Vector{String}
    ) -> Bool

Check if the OMM `section` has no comments and every field in `mapping` is `nothing`, in
which case the section is omitted from the output.
"""
function _xml_omm__section_is_empty(
    section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
    mapping::Vector{Pair{String, Symbol}},
    comments::Vector{String},
)
    return isempty(comments) && all(p -> isnothing(getfield(section, last(p))), mapping)
end
