## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using XML input.
#
############################################################################################

"""
    _xml_omm__parse(str::AbstractString) -> Union{Nothing, NamedTuple}
    _xml_omm__parse(xml::XML.Cursor) -> Union{Nothing, NamedTuple}

Parse the first Orbit Mean-Elements Message (OMM) from the XML input in `str` (or at the
`Cursor` `xml`), returning the container `(; version, header_fields, metadata_fields,
data_fields)` with the raw field values. If the document does not contain an OMM message,
`nothing` is returned.
"""
function _xml_omm__parse(str::AbstractString)
    # Open the XML file.
    xml = XML.Cursor(String(str))
    return _xml_omm__parse(xml)
end

function _xml_omm__parse(xml::XML.Cursor)
    for node in xml
        nodetype(node) === Element || continue
        _xml_omm__tag_is(node, "omm") && return _xml_omm__parse_element(node)
    end

    return nothing
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
    _xml_omm__parse_element(xml::Cursor) -> NamedTuple

Parse an OMM element at the `Cursor` `xml`, returning the container
`(; version, header_fields, metadata_fields, data_fields)` with the raw field values. The
version and the mandatory fields are checked afterwards by [`_omm_assemble`](@ref).
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

    version_attribute = get(xml, "version", nothing)
    version = nothing

    if !isnothing(version_attribute)
        version = tryparse(Float64, version_attribute)

        isnothing(version) && throw(
            OdmParseError(
                "The OMM element has an invalid `version` attribute: " *
                "\"$version_attribute\".",
            ),
        )
    end

    # The OMM element must contain exactly one `header` followed by one `body`, so we only
    # need to count the element children and check that the expected tag appears at each
    # position. The dictionaries are initialized here so that the locals stay
    # concretely typed.
    header_fields   = Dict{Symbol, Any}()
    metadata_fields = Dict{Symbol, Any}()
    data_fields     = Dict{Symbol, Any}()
    valid_children  = true
    child_count     = 0

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        child_count += 1

        if (child_count == 1) && _xml_omm__tag_is(node, "header")
            header_fields = _xml_omm__parse_header(node)
        elseif (child_count == 2) && _xml_omm__tag_is(node, "body")
            metadata_fields, data_fields = _xml_omm__parse_body(node)
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

    return (; version, header_fields, metadata_fields, data_fields)
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
        fields::Dict{Symbol, Any},
        xml::Cursor,
        mapping::Vector{Pair{String, Symbol}},
        comments_key::Symbol,
        description::String
    ) -> Nothing

Parse an OMM section composed only of scalar elements at the `Cursor` `xml`, storing the raw
field values in `fields`. The recognized keywords and their fields are given by `mapping`,
the comments are stored in `fields[comments_key]` when present, and `description` names the
section fields in error messages (e.g. `"metadata field"`).

The tags are matched ignoring the ASCII case, and empty values are skipped, allowing
real-world files with omitted values to be processed.
"""
function _xml_omm__parse_section!(
    fields::Dict{Symbol, Any},
    xml::XML.Cursor,
    mapping::Vector{Pair{String, Symbol}},
    comments_key::Symbol,
    description::String,
)
    comments = String[]
    seen     = UInt32(0)

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

        keyword, field = mapping[i]

        # An empty value is treated as an absent field.
        isempty(v) && continue

        fields[field] = _omm_parse_field_value(field, v, keyword)
    end

    isempty(comments) || (fields[comments_key] = comments)

    return nothing
end

# == Header Parsing ========================================================================

"""
    _xml_omm__parse_header(xml::Cursor) -> Dict{Symbol, Any}

Parse the header of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning a dictionary with the raw field values. Fields that are absent are
omitted from the dictionary; the mandatory fields are checked afterwards by
[`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_header(xml::XML.Cursor)
    fields = Dict{Symbol, Any}()

    _xml_omm__parse_section!(
        fields, xml, _OMM_HEADER_KEYWORD_TO_FIELD, :comments, "header field"
    )

    return fields
end

# == Body Parsing ==========================================================================

"""
    _xml_omm__parse_body(xml::Cursor) -> Tuple{Dict{Symbol, Any}, Dict{Symbol, Any}}

Parse the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml` representation,
returning dictionaries with the raw field values of the metadata and data sections of its
single segment.
"""
function _xml_omm__parse_body(xml::XML.Cursor)
    segment = nothing
    segment_count = 0

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        _xml_omm__tag_is(node, "segment") ||
            throw(OdmParseError("Unknown OMM body element `$(tag(node))`."))

        segment_count += 1

        if segment_count == 1
            segment = _xml_omm__parse_segment(node)
        else
            skip_element!(node)
        end
    end

    segment_count == 0 && throw(OdmParseError("The OMM body is missing the segment."))
    segment_count > 1 && throw(
        OdmParseError("The OMM body contains multiple segments, which is not supported."),
    )

    return segment
end

# -- Body Segment Parsing ------------------------------------------------------------------

"""
    _xml_omm__parse_segment(xml::Cursor) -> Tuple{Dict{Symbol, Any}, Dict{Symbol, Any}}

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning dictionaries with the raw field values of its metadata and data
sections.
"""
function _xml_omm__parse_segment(xml::XML.Cursor)
    metadata = nothing
    data = nothing

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        if _xml_omm__tag_is(node, "metadata")
            !isnothing(metadata) && throw(
                OdmParseError("The OMM segment contains duplicate metadata sections.")
            )
            metadata = _xml_omm__parse_metadata(node)
        elseif _xml_omm__tag_is(node, "data")
            !isnothing(data) &&
                throw(OdmParseError("The OMM segment contains duplicate data sections."))
            data = _xml_omm__parse_data(node)
        else
            throw(OdmParseError("Unknown OMM segment element `$(tag(node))`."))
        end
    end

    isnothing(metadata) &&
        throw(OdmParseError("The OMM segment is missing the metadata section."))

    isnothing(data) && throw(OdmParseError("The OMM segment is missing the data section."))

    return (metadata, data)
end

"""
    _xml_omm__parse_metadata(xml::Cursor) -> Dict{Symbol, Any}

Parse the metadata of the segment body of an Orbit Mean-Elements Message (OMM) from a
`Cursor` `xml` representation, returning a dictionary with the raw field values. Fields that
are absent are omitted from the dictionary; the mandatory fields are checked afterwards by
[`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_metadata(xml::XML.Cursor)
    fields = Dict{Symbol, Any}()

    _xml_omm__parse_section!(
        fields, xml, _OMM_METADATA_KEYWORD_TO_FIELD, :comments, "metadata field"
    )

    return fields
end

"""
    _xml_omm__parse_data(xml::Cursor) -> Dict{Symbol, Any}

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) from a `Cursor`
`xml` representation, returning a dictionary with the raw field values of all data
subsections. Fields that are absent are omitted from the dictionary; the mandatory fields
are checked afterwards by [`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_data(xml::XML.Cursor)
    fields        = Dict{Symbol, Any}()
    data_comments = String[]
    seen_sections = UInt8(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = tag(node)::SubString{String}

        if _ascii_iequal(lt, "COMMENT")
            push!(data_comments, _xml_omm__scalar_value(node))
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
                fields,
                node,
                _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD,
                :mean_elements_comments,
                "mean-elements field",
            )
        elseif i == 2
            _xml_omm__parse_section!(
                fields,
                node,
                _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
                :spacecraft_parameters_comments,
                "spacecraft parameter",
            )
        elseif i == 3
            _xml_omm__parse_section!(
                fields,
                node,
                _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD,
                :tle_parameters_comments,
                "TLE parameter",
            )
        elseif i == 4
            covariance_fields = Dict{Symbol, Any}()

            _xml_omm__parse_section!(
                covariance_fields,
                node,
                _OMM_COVARIANCE_KEYWORD_TO_FIELD,
                :comments,
                "covariance element",
            )

            fields[:covariance_matrix] = covariance_fields
        else
            user_defined_parameters = _xml_omm__parse_user_defined_parameters(node)

            # An empty section is normalized to an absent field so that every format
            # yields the same message.
            isempty(user_defined_parameters) ||
                (fields[:user_defined_parameters] = user_defined_parameters)
        end
    end

    isempty(data_comments) || (fields[:comments] = data_comments)

    return fields
end

"""
    _xml_omm__parse_user_defined_parameters(xml::Cursor) -> Vector{Pair{String, String}}

Parse an OMM `userDefinedParameters` section at the cursor's current position, matching
the tags ignoring the ASCII case. An `OdmParseError` is thrown if the section contains an
unknown element or a `USER_DEFINED` element without the `parameter` attribute.
"""
function _xml_omm__parse_user_defined_parameters(xml::XML.Cursor)
    parameters = Pair{String, String}[]

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

    return parameters
end
