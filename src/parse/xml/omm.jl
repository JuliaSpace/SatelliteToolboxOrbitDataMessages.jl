## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using XML input.
#
############################################################################################

"""
    _xml_omm__parse(str::AbstractString) -> _OmmBuilder

Parse the first Orbit Mean-Elements Message (OMM) from the XML input in `str`, returning
the builder with the raw field values.

The document can be a stand-alone OMM or a Navigation Data Message (NDM), in which case the
first wrapped OMM is parsed and the other messages are skipped. An `OdmParseError` is
thrown if the root tag is not recognized or the document does not contain an OMM.
"""
function _xml_omm__parse(str::AbstractString)
    # Open the XML file.
    xml       = XML.Cursor(String(str))
    root_node = _xml__root_element(xml)

    if _xml_omm__tag_is(root_node, "ndm")
        XML.@for_each_child root_node node begin
            nodetype(node) === Element || continue
            _xml_omm__tag_is(node, "omm") && return _xml_omm__parse_element(node)
            skip_element!(node)
        end

        throw(OdmParseError("The NDM does not contain an OMM."))
    end

    _xml_omm__tag_is(root_node, "omm") && return _xml_omm__parse_element(root_node)

    isnothing(_xml_odm__message_index(root_node)) &&
        throw(OdmParseError("The root tag `$(tag(root_node))` is not recognized."))

    throw(OdmParseError("The document contains a `$(tag(root_node))` instead of an OMM."))
end

# Sections of the OMM data element, in the order defined by the CCSDS 502.0-B-3 standard.
const _XML_OMM__DATA_SECTIONS = (
    "meanElements",
    "spacecraftParameters",
    "tleParameters",
    "covarianceMatrix",
    "userDefinedParameters",
)

"""
    _xml_omm__tag_is(node::XML.Cursor, name::String) -> Bool

Check if the tag of `node` matches `name`, ignoring the ASCII case. The comparison does
not allocate, so it can be used for every element of the document.
"""
function _xml_omm__tag_is(node::XML.Cursor, name::String)
    node_tag = tag(node)
    isnothing(node_tag) && return false
    return _ascii_iequal(node_tag, name)
end

"""
    _xml_omm__parse_element(xml::Cursor) -> _OmmBuilder

Parse an OMM element at the `Cursor` `xml`, returning the builder with the raw field
values. The version and the mandatory fields are checked afterwards by
[`_omm_assemble`](@ref).
"""
function _xml_omm__parse_element(xml::XML.Cursor)
    _xml_omm__tag_is(xml, "omm") ||
        throw(OdmParseError("The provided XML does not contain an OMM element."))

    # Extract the version attribute.
    id = get(xml, "id", nothing)

    (!isnothing(id) && _ascii_iequal(id, "CCSDS_OMM_VERS")) || throw(
        OdmParseError(
            "The OMM element is missing the required `id = CCSDS_OMM_VERS` attribute."
        ),
    )

    builder           = _OmmBuilder()
    version_attribute = get(xml, "version", nothing)

    if !isnothing(version_attribute)
        version = tryparse(Float64, version_attribute)

        isnothing(version) && throw(
            OdmParseError(
                "The OMM element has an invalid `version` attribute: " *
                "\"$version_attribute\".",
            ),
        )

        builder.version = version
    end

    # The OMM element must contain exactly one `header` followed by one `body`, so we only
    # need to count the element children and check that the expected tag appears at each
    # position.
    valid_children = true
    child_count    = 0

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        child_count += 1

        if (child_count == 1) && _xml_omm__tag_is(node, "header")
            _xml_omm__parse_section!(
                builder.header,
                node,
                _OMM_HEADER_KEYWORD_TO_FIELD,
                builder.header.comments,
                "header field",
            )
        elseif (child_count == 2) && _xml_omm__tag_is(node, "body")
            _xml_omm__parse_body!(builder, node)
        else
            valid_children = false
            skip_element!(node)
        end
    end

    (valid_children && (child_count == 2)) || throw(
        OdmParseError(
            "The OMM element must contain exactly one `header` followed by one `body`."
        ),
    )

    return builder
end

"""
    _xml_omm__scalar_value(xml::Cursor) -> SubString{String}

Read the text or CDATA value of the current OMM scalar element while advancing the cursor
past that element. Non-value child nodes are ignored.

All text and CDATA chunks are concatenated and the surrounding whitespace is stripped,
matching the whitespace-collapse behavior of the XML schema types used by the CCSDS
502.0-B-3 standard.
"""
function _xml_omm__scalar_value(xml::XML.Cursor)
    # The value is composed of a single text chunk in the vast majority of cases, so the
    # chunks are only concatenated when a second one appears, avoiding intermediate string
    # allocations.
    result = nothing

    XML.@for_each_child xml node begin
        if nodetype(node) === XML.Text || nodetype(node) === XML.CData
            chunk  = value(node)
            result = isnothing(result) ? chunk : string(result, chunk)
        elseif nodetype(node) === Element
            skip_element!(node)
        end
    end

    # Returning a `SubString` avoids copying the value: the numeric fields (the large
    # majority) are parsed directly from it, and the string fields are converted once by
    # `_omm_parse_field`.
    return strip(something(result, ""))
end

"""
    _xml_omm__parse_section!(
        builder,
        xml::Cursor,
        mapping::Vector{Pair{String, Symbol}},
        comments::Vector{String},
        description::String
    ) -> Nothing

Parse an OMM section composed only of scalar elements at the `Cursor` `xml`, storing the raw
field values in the section `builder`. The recognized keywords and their fields are given
by `mapping`, the comments are pushed to `comments`, and `description` names the section
fields in error messages (e.g. `"metadata field"`).

The tags are matched ignoring the ASCII case, and empty values are skipped, allowing
real-world files with omitted values to be processed.
"""
function _xml_omm__parse_section!(
    builder,
    xml::XML.Cursor,
    mapping::Vector{Pair{String, Symbol}},
    comments::Vector{String},
    description::String,
)
    seen = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = tag(node)::SubString{String}
        v  = _xml_omm__scalar_value(node)

        if _ascii_iequal(lt, "COMMENT")
            push!(comments, v)
            continue
        end

        # The mapping is an ordered vector of pairs, so we perform a linear search. The
        # sections are small, hence the lookup cost is negligible.
        i = findfirst(p -> _ascii_iequal(first(p), lt), mapping)
        isnothing(i) &&
            throw(OdmParseError("Unknown OMM $description `$lt`."; keyword = lt))

        # Every mapping has at most 22 entries, so a bitmask over the mapping index
        # detects duplicates without allocating a `Set`.
        mask = UInt32(1) << (i - 1)
        (seen & mask) != 0 &&
            throw(OdmParseError("Duplicate OMM $description `$lt`."; keyword = lt))
        seen |= mask

        # An empty value is treated as an absent field.
        isempty(v) && continue

        keyword, field = mapping[i]
        _omm_set_field!(builder, field, v, keyword)
    end

    return nothing
end

# == Body Parsing ==========================================================================

"""
    _xml_omm__parse_body!(builder::_OmmBuilder, xml::Cursor) -> Nothing

Parse the body of an Orbit Mean-Elements Message (OMM) at the `Cursor` `xml`, storing the
raw field values of the metadata and data sections of its single segment in `builder`.
"""
function _xml_omm__parse_body!(builder::_OmmBuilder, xml::XML.Cursor)
    segment_count = 0

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        _xml_omm__tag_is(node, "segment") ||
            throw(OdmParseError("Unknown OMM body element `$(tag(node))`."))

        segment_count += 1

        if segment_count == 1
            _xml_omm__parse_segment!(builder, node)
        else
            skip_element!(node)
        end
    end

    segment_count == 0 && throw(OdmParseError("The OMM body is missing the segment."))
    segment_count > 1 && throw(
        OdmParseError("The OMM body contains multiple segments, which is not supported."),
    )

    return nothing
end

# -- Body Segment Parsing ------------------------------------------------------------------

"""
    _xml_omm__parse_segment!(builder::_OmmBuilder, xml::Cursor) -> Nothing

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) at the `Cursor` `xml`,
storing the raw field values of its metadata and data sections in `builder`.
"""
function _xml_omm__parse_segment!(builder::_OmmBuilder, xml::XML.Cursor)
    has_metadata = false
    has_data     = false

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        if _xml_omm__tag_is(node, "metadata")
            has_metadata && throw(
                OdmParseError("The OMM segment contains duplicate metadata sections.")
            )
            has_metadata = true

            _xml_omm__parse_section!(
                builder.metadata,
                node,
                _OMM_METADATA_KEYWORD_TO_FIELD,
                builder.metadata.comments,
                "metadata field",
            )
        elseif _xml_omm__tag_is(node, "data")
            has_data &&
                throw(OdmParseError("The OMM segment contains duplicate data sections."))
            has_data = true

            _xml_omm__parse_data!(builder.data, node)
        else
            throw(OdmParseError("Unknown OMM segment element `$(tag(node))`."))
        end
    end

    has_metadata ||
        throw(OdmParseError("The OMM segment is missing the metadata section."))

    has_data || throw(OdmParseError("The OMM segment is missing the data section."))

    return nothing
end

"""
    _xml_omm__parse_data!(data::_OmmDataBuilder, xml::Cursor) -> Nothing

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) at the `Cursor`
`xml`, storing the raw field values of all data subsections in `data`.
"""
function _xml_omm__parse_data!(data::_OmmDataBuilder, xml::XML.Cursor)
    seen_sections = UInt8(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = tag(node)::SubString{String}

        if _ascii_iequal(lt, "COMMENT")
            push!(data.comments, _xml_omm__scalar_value(node))
            continue
        end

        i = findfirst(s -> _ascii_iequal(s, lt), _XML_OMM__DATA_SECTIONS)
        isnothing(i) && throw(OdmParseError("Unknown OMM data section `$lt`."))

        # A bitmask over the section index detects duplicates without allocating a `Set`.
        mask = UInt8(1) << (i - 1)
        (seen_sections & mask) != 0 &&
            throw(OdmParseError("Duplicate OMM data section `$lt`."))
        seen_sections |= mask

        if i == 1
            _xml_omm__parse_section!(
                data,
                node,
                _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD,
                data.mean_elements_comments,
                "mean-elements field",
            )
        elseif i == 2
            _xml_omm__parse_section!(
                data,
                node,
                _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
                data.spacecraft_parameters_comments,
                "spacecraft parameter",
            )
        elseif i == 3
            _xml_omm__parse_section!(
                data,
                node,
                _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD,
                data.tle_parameters_comments,
                "TLE parameter",
            )
        elseif i == 4
            covariance_matrix = _OmmCovarianceMatrixBuilder()

            _xml_omm__parse_section!(
                covariance_matrix,
                node,
                _OMM_COVARIANCE_KEYWORD_TO_FIELD,
                covariance_matrix.comments,
                "covariance element",
            )

            data.covariance_matrix = covariance_matrix
        else
            _xml_omm__parse_user_defined_parameters!(data.user_defined_parameters, node)
        end
    end

    return nothing
end

"""
    _xml_omm__parse_user_defined_parameters!(
        parameters::Vector{Pair{String, String}},
        xml::Cursor
    ) -> Nothing

Parse an OMM `userDefinedParameters` section at the cursor's current position, pushing the
parameters to `parameters` and matching the tags ignoring the ASCII case. An
`OdmParseError` is thrown if the section contains an unknown element or a `USER_DEFINED`
element without the `parameter` attribute.
"""
function _xml_omm__parse_user_defined_parameters!(
    parameters::Vector{Pair{String, String}}, xml::XML.Cursor
)
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        _xml_omm__tag_is(node, "USER_DEFINED") || throw(
            OdmParseError("Unknown user-defined parameter element `$(tag(node))`.")
        )

        key = get(node, "parameter", nothing)

        isnothing(key) && throw(
            OdmParseError(
                "OMM `USER_DEFINED` element is missing required attribute `parameter`.";
                keyword = "USER_DEFINED",
            ),
        )

        push!(parameters, String(key) => _xml_omm__scalar_value(node))
    end

    return nothing
end
