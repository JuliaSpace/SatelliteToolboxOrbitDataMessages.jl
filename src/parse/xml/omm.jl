## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using XML input.
#
############################################################################################

"""
    _xml_omm__parse(str::AbstractString, strict::Bool)

Parse the first Orbit Mean-Elements Message (OMM) from the XML input in `str`, returning the
container `(; version, header_fields, metadata_fields, data_fields)` with the raw field
values. If the document does not contain an OMM message, `nothing` is returned.
"""
function _xml_omm__parse(str::AbstractString, strict::Bool)
    # Open the XML file.
    xml = XML.Cursor(String(str))
    return _xml_omm__parse(xml, strict)
end

function _xml_omm__parse(xml::XML.Cursor, strict::Bool)
    for node in xml
        nodetype(node) === Element || continue
        t = _xml_omm__tag(node, strict)
        t == "omm" && return _xml_omm__parse_element(node, strict)
    end

    return nothing
end

# Map lowercase OMM structural tag names to their canonical schema-defined casing for
# case-insensitive parsing.
const _XML_OMM__STRUCTURAL_TAGS = Dict(
    "ndm"                   => "ndm",
    "omm"                   => "omm",
    "opm"                   => "opm",
    "oem"                   => "oem",
    "ocm"                   => "ocm",
    "header"                => "header",
    "body"                  => "body",
    "segment"               => "segment",
    "metadata"              => "metadata",
    "data"                  => "data",
    "meanelements"          => "meanElements",
    "spacecraftparameters"  => "spacecraftParameters",
    "tleparameters"         => "tleParameters",
    "covariancematrix"      => "covarianceMatrix",
    "userdefinedparameters" => "userDefinedParameters",
)

"""
    _xml_omm__tag(node::Cursor, strict::Bool) -> Union{String, Nothing}

Return the canonical OMM tag for `node`, matching case-insensitively unless `strict` is
`true`.
"""
function _xml_omm__tag(node::XML.Cursor, strict::Bool)
    node_tag = tag(node)
    (strict || isnothing(node_tag)) && return node_tag

    lowercase_tag = lowercase(node_tag)
    return get(_XML_OMM__STRUCTURAL_TAGS, lowercase_tag, uppercase(node_tag))
end

"""
    _xml_omm__parse_element(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM element at the `Cursor` `xml`, returning the container
`(; version, header_fields, metadata_fields, data_fields)` with the raw field values. The
version and the mandatory fields are checked afterwards by [`_omm_assemble`](@ref).
"""
function _xml_omm__parse_element(xml::XML.Cursor, strict::Bool)
    _xml_omm__tag(xml, strict) != "omm" && throw(
        ArgumentError("The provided XML does not contain an OMM element.")
    )

    # Extract the version attribute.
    id = get(xml, "id", nothing)
    valid_id = !isnothing(id) && (
        strict ? id == "CCSDS_OMM_VERS" : lowercase(id) == "ccsds_omm_vers"
    )
    !valid_id && throw(ArgumentError(
        "The OMM element is missing the required `id = CCSDS_OMM_VERS` attribute."
    ))

    version_attribute = get(xml, "version", nothing)
    version = nothing

    if !isnothing(version_attribute)
        version = tryparse(Float64, version_attribute)

        isnothing(version) && throw(ArgumentError(
            "The OMM element has an invalid `version` attribute: \"$version_attribute\"."
        ))
    end

    # The OMM element must contain exactly one `header` followed by one `body`, so we
    # only need to count the element children and check that the expected tag appears at
    # each position.
    header_fields  = nothing
    segment        = nothing
    valid_children = true
    child_count    = 0

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        child_count += 1

        if (child_count == 1) && (lt == "header")
            header_fields = _xml_omm__parse_header(node, strict)
        elseif (child_count == 2) && (lt == "body")
            segment = _xml_omm__parse_body(node, strict)
        else
            valid_children = false
            skip_element!(node)
        end
    end

    (valid_children && (child_count == 2)) || throw(ArgumentError(
        "The OMM element must contain exactly one `header` followed by one `body`."
    ))

    metadata_fields, data_fields = segment

    return (; version, header_fields, metadata_fields, data_fields)
end

"""
    _xml_omm__scalar_value(xml::Cursor) -> String

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

    isnothing(result) && return ""

    return String(strip(result))
end

"""
    _xml_omm__parse_section!(fields::Dict{Symbol, Any}, xml::Cursor, strict::Bool, mapping::Vector{Pair{String, Symbol}}, comments_key::Symbol, description::String) -> Nothing

Parse an OMM section composed only of scalar elements at the `Cursor` `xml`, storing the raw
field values in `fields`. The recognized keywords and their fields are given by `mapping`,
the comments are stored in `fields[comments_key]` when present, and `description` names the
section fields in error messages (e.g. `"metadata field"`).

Empty values are rejected when `strict` is `true` and skipped otherwise, allowing real-world
files with omitted values to be processed leniently.
"""
function _xml_omm__parse_section!(
    fields::Dict{Symbol, Any},
    xml::XML.Cursor,
    strict::Bool,
    mapping::Vector{Pair{String, Symbol}},
    comments_key::Symbol,
    description::String
)
    comments = String[]
    seen     = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)

        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        # The mapping is an ordered vector of pairs, so we perform a linear search. The
        # sections are small, hence the lookup cost is negligible.
        i     = findfirst(p -> first(p) == lt, mapping)
        field = isnothing(i) ? nothing : last(mapping[i])
        isnothing(field) && throw(ArgumentError("Unknown OMM $description `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM $description `$lt`."))
        push!(seen, lt)

        if isempty(v)
            strict && throw(ArgumentError("OMM field `$lt` cannot be empty."))
            continue
        end

        fields[field] = _omm_parse_field(_omm_field_type(field), v, lt)
    end

    isempty(comments) || (fields[comments_key] = comments)

    return nothing
end

# == Header Parsing ========================================================================

"""
    _xml_omm__parse_header(xml::Cursor, strict::Bool) -> Dict{Symbol, Any}

Parse the header of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning a dictionary with the raw field values. Fields that are absent are
omitted from the dictionary; the mandatory fields are checked afterwards by
[`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_header(xml::XML.Cursor, strict::Bool)
    fields = Dict{Symbol, Any}()

    _xml_omm__parse_section!(
        fields,
        xml,
        strict,
        _OMM_HEADER_KEYWORD_TO_FIELD,
        :comments,
        "header field"
    )

    # `CREATION_DATE` is checked here instead of in `_omm_check_mandatory_fields` because
    # its presence requirement is relaxed when parsing leniently, allowing real-world files
    # with an omitted creation date to be processed.
    strict && !haskey(fields, :creation_date) && throw(ArgumentError(
        "OMM header is missing required field `CREATION_DATE`."
    ))

    return fields
end

# == Body Parsing ==========================================================================

"""
    _xml_omm__parse_body(xml::Cursor, strict::Bool) -> Tuple{Dict{Symbol, Any}, Dict{Symbol, Any}}

Parse the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml` representation,
returning dictionaries with the raw field values of the metadata and data sections of its
single segment.
"""
function _xml_omm__parse_body(xml::XML.Cursor, strict::Bool)
    segment = nothing
    segment_count = 0

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        _xml_omm__tag(node, strict) == "segment" || throw(ArgumentError(
            "Unknown OMM body element."
        ))

        segment_count += 1

        if segment_count == 1
            segment = _xml_omm__parse_segment(node, strict)
        else
            skip_element!(node)
        end
    end

    segment_count == 0 && throw(ArgumentError("The OMM body is missing the segment."))
    segment_count > 1 && throw(ArgumentError(
        "The OMM body contains multiple segments, which is not supported."
    ))

    return segment
end

# -- Body Segment Parsing ------------------------------------------------------------------

"""
    _xml_omm__parse_segment(xml::Cursor, strict::Bool) -> Tuple{Dict{Symbol, Any}, Dict{Symbol, Any}}

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning dictionaries with the raw field values of its metadata and data
sections.
"""
function _xml_omm__parse_segment(xml::XML.Cursor, strict::Bool)
    metadata = nothing
    data = nothing

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue

        lt = _xml_omm__tag(node, strict)
        lt ∈ ("metadata", "data") || throw(ArgumentError("Unknown OMM segment element."))

        if lt == "metadata"
            !isnothing(metadata) && throw(ArgumentError(
                "The OMM segment contains duplicate metadata sections."
            ))
            metadata = _xml_omm__parse_metadata(node, strict)
        else
            !isnothing(data) && throw(ArgumentError(
                "The OMM segment contains duplicate data sections."
            ))
            data = _xml_omm__parse_data(node, strict)
        end
    end

    isnothing(metadata) && throw(ArgumentError(
        "The OMM segment is missing the metadata section."
    ))

    isnothing(data) && throw(ArgumentError(
        "The OMM segment is missing the data section."
    ))

    return (metadata, data)
end

"""
    _xml_omm__parse_metadata(xml::Cursor, strict::Bool) -> Dict{Symbol, Any}

Parse the metadata of the segment body of an Orbit Mean-Elements Message (OMM) from a
`Cursor` `xml` representation, returning a dictionary with the raw field values. Fields that
are absent are omitted from the dictionary; the mandatory fields are checked afterwards by
[`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_metadata(xml::XML.Cursor, strict::Bool)
    fields = Dict{Symbol, Any}()

    _xml_omm__parse_section!(
        fields,
        xml,
        strict,
        _OMM_METADATA_KEYWORD_TO_FIELD,
        :comments,
        "metadata field"
    )

    return fields
end

"""
    _xml_omm__parse_data(xml::Cursor, strict::Bool) -> Dict{Symbol, Any}

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) from a `Cursor`
`xml` representation, returning a dictionary with the raw field values of all data
subsections. Fields that are absent are omitted from the dictionary; the mandatory fields
are checked afterwards by [`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_data(xml::XML.Cursor, strict::Bool)
    fields        = Dict{Symbol, Any}()
    data_comments = String[]
    seen_sections = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)

        if lt == "COMMENT"
            push!(data_comments, _xml_omm__scalar_value(node))
            continue
        end

        lt ∉ (
            "meanElements",
            "spacecraftParameters",
            "tleParameters",
            "covarianceMatrix",
            "userDefinedParameters",
        ) && throw(ArgumentError("Unknown OMM data section `$lt`."))

        lt in seen_sections && throw(ArgumentError("Duplicate OMM data section `$lt`."))
        push!(seen_sections, lt)

        if lt == "meanElements"
            _xml_omm__parse_section!(
                fields,
                node,
                strict,
                _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD,
                :mean_elements_comments,
                "mean-elements field"
            )
        elseif lt == "spacecraftParameters"
            _xml_omm__parse_section!(
                fields,
                node,
                strict,
                _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
                :spacecraft_parameters_comments,
                "spacecraft parameter"
            )
        elseif lt == "tleParameters"
            _xml_omm__parse_section!(
                fields,
                node,
                strict,
                _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD,
                :tle_parameters_comments,
                "TLE parameter"
            )
        elseif lt == "covarianceMatrix"
            covariance_fields = Dict{Symbol, Any}()

            _xml_omm__parse_section!(
                covariance_fields,
                node,
                strict,
                _OMM_COVARIANCE_KEYWORD_TO_FIELD,
                :comments,
                "covariance element"
            )

            fields[:covariance_matrix] = covariance_fields
        else
            fields[:user_defined_parameters] =
                _xml_omm__parse_user_defined_parameters(node, strict)
        end
    end

    isempty(data_comments) || (fields[:comments] = data_comments)

    return fields
end

"""
    _xml_omm__parse_user_defined_parameters(
        xml::Cursor,
        strict::Bool
    ) -> Vector{Pair{String,String}}

Parse an OMM `userDefinedParameters` section at the cursor's current position.
"""
function _xml_omm__parse_user_defined_parameters(xml::XML.Cursor, strict::Bool)
    parameters = Pair{String, String}[]

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        lt == "USER_DEFINED" || throw(ArgumentError(
            "Unknown user-defined parameter element `$lt`."
        ))

        key = get(node, "parameter", nothing)

        isnothing(key) && throw(ArgumentError(
            "OMM `USER_DEFINED` element is missing required attribute `parameter`."
        ))

        push!(parameters, String(key) => _xml_omm__scalar_value(node))
    end

    return parameters
end
