## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM).
#
############################################################################################

export parse_omm, parse_omms

"""
    parse_omm(str::AbstractString; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) in the string `str` and return the parsed
message. The input format must be XML.

    parse_omm(xml::Cursor; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml` and return the parsed
message.

If the XML is a Navigation Data Message (NDM), only the first OMM message is returned. If
the file does not contain an OMM message, `nothing` is returned.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omm(str::AbstractString; strict::Bool = true)
    # Open the XML file.
    xml = XML.Cursor(String(str))
    return parse_omm(xml; strict)
end

function parse_omm(xml::XML.Cursor; strict::Bool = true)
    # Get the document root node.
    root_node = next!(xml)
    while !isnothing(root_node) && nodetype(root_node) !== Element
        root_node = next!(xml)
    end
    isnothing(root_node) && return nothing

    t = _omm_tag(root_node, strict)
    t == "omm" && return _parse_omm(root_node, strict)

    # In a Navigation Data Message (NDM), only the direct children of the root element can
    # contain OMMs, matching the traversal performed by `parse_odm`.
    if t == "ndm"
        result = nothing
        XML.@for_each_child root_node node begin
            nodetype(node) === Element || continue
            if isnothing(result) && _omm_tag(node, strict) == "omm"
                result = _parse_omm(node, strict)
            else
                skip_element!(node)
            end
        end
        return result
    end

    return nothing
end

"""
    parse_omms(str::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) in the string `str` and return the
parsed messages. The input format must be XML.

    parse_omms(xml::Cursor; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) from a `Cursor` `xml` and return the
parsed messages.

If the XML is a Navigation Data Message (NDM), only the OMM messages are returned; other
message types (OPM, OEM, OCM) are skipped with a warning. If the document does not contain
an OMM message, an empty vector is returned. If the root tag is not recognized, an
`ArgumentError` is thrown.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omms(str::AbstractString; strict::Bool = true)
    # Open the XML file.
    xml = XML.Cursor(String(str))
    return parse_omms(xml; strict)
end

function parse_omms(xml::XML.Cursor; strict::Bool = true)
    messages = parse_odm(xml; strict)
    return OrbitMeanElementsMessage[
        message for message in messages if message isa OrbitMeanElementsMessage
    ]
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# Map lowercase OMM structural tag names to their canonical schema-defined casing for
# case-insensitive parsing.
const _OMM_STRUCTURAL_TAGS = Dict(
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

# Canonical structural tag names for the fast-path exact match in `_omm_tag`.
const _OMM_CANONICAL_STRUCTURAL_TAGS = Set{String}(values(_OMM_STRUCTURAL_TAGS))

# Map all-uppercase structural tag names to their canonical casing for the `_omm_tag` fast
# path that avoids lowercasing every tag.
const _OMM_UPPERCASE_STRUCTURAL_TAGS = Dict{String, String}(
    uppercase(k) => v for (k, v) in _OMM_STRUCTURAL_TAGS
)

"""
    _omm_tag(node::Cursor, strict::Bool) -> Union{String, Nothing}

Return the canonical OMM tag for `node`, matching case-insensitively unless `strict` is
`true`.
"""
function _omm_tag(node::XML.Cursor, strict::Bool)
    node_tag = tag(node)
    (strict || isnothing(node_tag)) && return node_tag

    # Fast paths for tags that are already canonical, avoiding the `lowercase` and
    # `uppercase` allocations for every node in a well-cased document.
    node_tag in _OMM_CANONICAL_STRUCTURAL_TAGS && return node_tag

    if !any(islowercase, node_tag)
        structural_tag = get(_OMM_UPPERCASE_STRUCTURAL_TAGS, node_tag, nothing)
        return isnothing(structural_tag) ? node_tag : structural_tag
    end

    lowercase_tag = lowercase(node_tag)
    return get(_OMM_STRUCTURAL_TAGS, lowercase_tag, uppercase(node_tag))
end

"""
    _parse_omm(xml::Cursor, strict::Bool) -> OrbitMeanElementsMessage

Parse an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml` representation.
"""
function _parse_omm(xml::XML.Cursor, strict::Bool)
    _omm_tag(xml, strict) != "omm" && throw(
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
    isnothing(version_attribute) && throw(ArgumentError(
        "The OMM element is missing the required `version` attribute."
    ))

    version = VersionNumber(version_attribute)

    version ∉ (v"2.0.0", v"3.0.0") &&
        throw(ArgumentError("Unsupported OMM version: $version."))

    # Track the structure with flags instead of accumulating the element tags in a vector.
    # The message is valid only if the children are exactly one `header` followed by one
    # `body`.
    header = nothing
    body = nothing
    valid_structure = true
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        if lt == "header" && isnothing(header) && isnothing(body)
            header = _parse_omm_header(node, strict, version)
        elseif lt == "body" && !isnothing(header) && isnothing(body)
            body = _parse_omm_body(node, strict, version)
        else
            valid_structure = false
            skip_element!(node)
        end
    end
    (valid_structure && !isnothing(header) && !isnothing(body)) || throw(ArgumentError(
        "The OMM element must contain exactly one `header` followed by one `body`."
    ))

    return OrbitMeanElementsMessage(version, header, body)
end

"""
    _omm_scalar_value(xml::Cursor) -> String

Read the text or CDATA value of the current OMM scalar element while advancing the cursor
past that element. Non-value child nodes are ignored.

All text and CDATA chunks are concatenated and the surrounding whitespace is stripped,
matching the whitespace-collapse behavior of the XML schema types used by the CCSDS
502.0-B-3 standard.
"""
function _omm_scalar_value(xml::XML.Cursor)
    # Virtually every scalar element contains exactly one text chunk, so we keep the first
    # chunk as is and only fall back to an `IOBuffer` when a second chunk appears, avoiding
    # quadratic string concatenation.
    first_chunk::Union{Nothing, String} = nothing
    buffer::Union{Nothing, IOBuffer} = nothing

    XML.@for_each_child xml node begin
        if nodetype(node) === XML.Text || nodetype(node) === XML.CData
            chunk = String(value(node))

            if isnothing(first_chunk)
                first_chunk = chunk
            else
                if isnothing(buffer)
                    buffer = IOBuffer()
                    print(buffer, first_chunk)
                end
                print(buffer, chunk)
            end
        elseif nodetype(node) === Element
            skip_element!(node)
        end
    end

    isnothing(first_chunk) && return ""
    result = isnothing(buffer) ? first_chunk : String(take!(buffer))
    return String(strip(result))
end

"""
    _parse_omm_number(::Type{T}, v::AbstractString, field::AbstractString) where T <: Number -> T

Parse the string `v` as a number of type `T`, throwing an `ArgumentError` that names the
OMM `field` if the value is not a valid number.
"""
function _parse_omm_number(
    ::Type{T},
    v::AbstractString,
    field::AbstractString
) where T <: Number
    number = tryparse(T, v)
    isnothing(number) && throw(ArgumentError(
        "OMM field `$field` contains an invalid value: \"$v\"."
    ))
    return number
end

# == Header Parsing ========================================================================

# Known fields of the OMM header section.
const _OMM_HEADER_FIELDS = (
    "CLASSIFICATION",
    "CREATION_DATE",
    "ORIGINATOR",
    "MESSAGE_ID",
)

"""
    _parse_omm_header(xml::Cursor, strict::Bool, version::VersionNumber) -> OmmHeader

Parse the header of an Orbit Mean-Elements Message (OMM) with schema `version` from a
`Cursor` `xml` representation.
"""
function _parse_omm_header(xml::XML.Cursor, strict::Bool, version::VersionNumber)
    comments       = String[]
    classification = nothing
    creation_date  = nothing
    originator     = nothing
    message_id     = nothing
    seen           = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)

        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        # Detect unknown and duplicate fields using a bitmask over the known field list,
        # avoiding a per-call `Set` allocation.
        i = findfirst(==(lt), _OMM_HEADER_FIELDS)
        isnothing(i) && throw(ArgumentError("Unknown OMM header field `$lt`."))
        strict && version == v"2.0" && lt ∈ ("CLASSIFICATION", "MESSAGE_ID") && throw(
            ArgumentError("OMM header field `$lt` is not valid in OMM version 2.0.")
        )
        seen & (UInt32(1) << i) != 0 &&
            throw(ArgumentError("Duplicate OMM header field `$lt`."))
        seen |= UInt32(1) << i

        if lt == "CLASSIFICATION"
            classification = v
        elseif lt == "CREATION_DATE"
            if isempty(v)
                strict && throw(ArgumentError(
                    "OMM field `CREATION_DATE` cannot be empty."
                ))
            else
                creation_date = _parse_ndm_date(v)
            end
        elseif lt == "ORIGINATOR"
            strict && isempty(v) && throw(ArgumentError(
                "OMM field `ORIGINATOR` cannot be empty."
            ))
            originator = v
        elseif lt == "MESSAGE_ID"
            message_id = v
        end
    end

    # Check if all required fields are present.
    if strict && isnothing(creation_date)
        throw(ArgumentError("OMM header is missing required field `CREATION_DATE`."))
    end

    if isnothing(originator)
        throw(ArgumentError("OMM header is missing required field `ORIGINATOR`."))
    end

    return OmmHeader(
        comments,
        classification,
        creation_date,
        originator,
        message_id
    )
end

# == Body Parsing ==========================================================================

"""
    _parse_omm_body(xml::Cursor, strict::Bool, version::VersionNumber) -> OmmBody

Parse the body of an Orbit Mean-Elements Message (OMM) with schema `version` from a
`Cursor` `xml` representation.
"""
function _parse_omm_body(xml::XML.Cursor, strict::Bool, version::VersionNumber)
    segment = nothing
    segment_count = 0
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        _omm_tag(node, strict) == "segment" ||
            throw(ArgumentError("Unknown OMM body element."))
        segment_count += 1
        if segment_count == 1
            segment = _parse_omm_segment(node, strict, version)
        else
            skip_element!(node)
        end
    end

    segment_count == 0 && throw(ArgumentError("The OMM body is missing the segment."))
    segment_count > 1 && throw(ArgumentError(
        "The OMM body contains multiple segments, which is not supported."
    ))

    return OmmBody(segment)
end

# -- Body Segment Parsing ------------------------------------------------------------------

"""
    _parse_omm_segment(xml::Cursor, strict::Bool, version::VersionNumber) -> OmmSegment

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) with schema `version`
from a `Cursor` `xml` representation.
"""
function _parse_omm_segment(xml::XML.Cursor, strict::Bool, version::VersionNumber)
    metadata = nothing
    data = nothing
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        lt ∈ ("metadata", "data") ||
            throw(ArgumentError("Unknown OMM segment element."))
        if lt == "metadata"
            !isnothing(metadata) && throw(ArgumentError(
                "The OMM segment contains duplicate metadata sections."
            ))
            metadata = _parse_omm_metadata(node, strict)
        else
            !isnothing(data) && throw(ArgumentError(
                "The OMM segment contains duplicate data sections."
            ))
            data = _parse_omm_data(node, strict, version)
        end
    end

    isnothing(metadata) && throw(ArgumentError(
        "The OMM segment is missing the metadata section."
    ))
    isnothing(data) && throw(ArgumentError(
        "The OMM segment is missing the data section."
    ))

    return OmmSegment(metadata, data)
end

# Known fields of the OMM metadata section.
const _OMM_METADATA_FIELDS = (
    "OBJECT_NAME",
    "OBJECT_ID",
    "CENTER_NAME",
    "REF_FRAME",
    "REF_FRAME_EPOCH",
    "TIME_SYSTEM",
    "MEAN_ELEMENT_THEORY",
)

"""
    _parse_omm_metadata(xml::Cursor, strict::Bool) -> OmmMetadata

Parse the metadata of the segment body of an Orbit Mean-Elements Message (OMM) from a
`Cursor` `xml` representation.
"""
function _parse_omm_metadata(xml::XML.Cursor, strict::Bool)
    comments            = String[]
    object_name         = nothing
    object_id           = nothing
    center_name         = nothing
    ref_frame           = nothing
    ref_frame_epoch     = nothing
    time_system         = nothing
    mean_element_theory = nothing
    seen                = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)

        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        i = findfirst(==(lt), _OMM_METADATA_FIELDS)
        isnothing(i) && throw(ArgumentError("Unknown OMM metadata field `$lt`."))
        seen & (UInt32(1) << i) != 0 &&
            throw(ArgumentError("Duplicate OMM metadata field `$lt`."))
        seen |= UInt32(1) << i

        if lt == "OBJECT_NAME"
            object_name = v
        elseif lt == "OBJECT_ID"
            object_id = v
        elseif lt == "CENTER_NAME"
            center_name = v
        elseif lt == "REF_FRAME"
            ref_frame = v
        elseif lt == "REF_FRAME_EPOCH"
            # `REF_FRAME_EPOCH` is optional, so we tolerate an empty tag in non-strict
            # mode and treat it as absent.
            if isempty(v)
                strict && throw(ArgumentError(
                    "OMM field `REF_FRAME_EPOCH` cannot be empty."
                ))
            else
                ref_frame_epoch = _parse_ndm_date(v)
            end
        elseif lt == "TIME_SYSTEM"
            time_system = v
        elseif lt == "MEAN_ELEMENT_THEORY"
            mean_element_theory = v
        end
    end

    # Check if all required fields are present.
    isnothing(object_name) && throw(ArgumentError(
        "OMM metadata is missing required field `OBJECT_NAME`."
    ))

    isnothing(object_id) && throw(ArgumentError(
        "OMM metadata is missing required field `OBJECT_ID`."
    ))

    isnothing(center_name) && throw(ArgumentError(
        "OMM metadata is missing required field `CENTER_NAME`."
    ))

    isnothing(ref_frame) && throw(ArgumentError(
        "OMM metadata is missing required field `REF_FRAME`."
    ))

    isnothing(time_system) && throw(ArgumentError(
        "OMM metadata is missing required field `TIME_SYSTEM`."
    ))

    isnothing(mean_element_theory) && throw(ArgumentError(
        "OMM metadata is missing required field `MEAN_ELEMENT_THEORY`."
    ))

    return OmmMetadata(
        comments,
        object_name,
        object_id,
        center_name,
        ref_frame,
        ref_frame_epoch,
        time_system,
        mean_element_theory
    )
end

# Known sections of the OMM data element.
const _OMM_DATA_SECTIONS = (
    "meanElements",
    "spacecraftParameters",
    "tleParameters",
    "covarianceMatrix",
    "userDefinedParameters",
)

"""
    _parse_omm_data(xml::Cursor, strict::Bool, version::VersionNumber) -> OmmData

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) with schema
`version` from a `Cursor` `xml` representation.
"""
function _parse_omm_data(xml::XML.Cursor, strict::Bool, version::VersionNumber)
    data_comments = String[]
    mean_elements::Union{Nothing, _OmmMeanElementsNT} = nothing
    spacecraft_parameters::Union{Nothing, _OmmSpacecraftParametersNT} = nothing
    tle_parameters::Union{Nothing, _OmmTleParametersNT} = nothing
    covariance_matrix::Union{Nothing, OmmCovarianceMatrix} = nothing
    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}} = nothing
    seen_sections = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        if lt == "COMMENT"
            push!(data_comments, _omm_scalar_value(node))
            continue
        end

        i = findfirst(==(lt), _OMM_DATA_SECTIONS)
        isnothing(i) && throw(ArgumentError("Unknown OMM data section `$lt`."))
        seen_sections & (UInt32(1) << i) != 0 &&
            throw(ArgumentError("Duplicate OMM data section `$lt`."))
        seen_sections |= UInt32(1) << i

        if lt == "meanElements"
            mean_elements = _parse_omm_mean_elements(node, strict)
        elseif lt == "spacecraftParameters"
            spacecraft_parameters = _parse_omm_spacecraft_parameters(node, strict)
        elseif lt == "tleParameters"
            tle_parameters = _parse_omm_tle_parameters(node, strict, version)
        elseif lt == "covarianceMatrix"
            covariance_matrix = _parse_omm_covariance_matrix(node, strict)
        else
            user_defined_parameters = _parse_omm_user_defined_parameters(node, strict)
        end
    end

    isnothing(mean_elements) && throw(ArgumentError(
        "The OMM data is missing the required section `meanElements`."
    ))
    spacecraft_parameters = something(
        spacecraft_parameters,
        _empty_omm_spacecraft_parameters()
    )
    tle_parameters = something(tle_parameters, _empty_omm_tle_parameters())

    return OmmData(
        ;
        comments = data_comments,
        mean_elements...,
        spacecraft_parameters...,
        tle_parameters...,
        covariance_matrix,
        user_defined_parameters,
    )
end

# Known fields of the OMM `meanElements` section.
const _OMM_MEAN_ELEMENTS_FIELDS = (
    "EPOCH",
    "SEMI_MAJOR_AXIS",
    "MEAN_MOTION",
    "ECCENTRICITY",
    "INCLINATION",
    "RA_OF_ASC_NODE",
    "ARG_OF_PERICENTER",
    "MEAN_ANOMALY",
    "GM",
)

# Concrete `NamedTuple` type returned by `_parse_omm_mean_elements`. Using a fixed type
# keeps the return type value-independent, avoiding dynamic dispatch when the result is
# splatted into the `OmmData` constructor.
const _OmmMeanElementsNT = @NamedTuple{
    mean_elements_comments::Vector{String},
    epoch::NanoDate,
    semi_major_axis::Union{Nothing, Float64},
    mean_motion::Union{Nothing, Float64},
    eccentricity::Float64,
    inclination::Float64,
    raan::Float64,
    arg_of_pericenter::Float64,
    mean_anomaly::Float64,
    GM::Union{Nothing, Float64},
}

"""
    _parse_omm_mean_elements(xml::Cursor, strict::Bool) -> _OmmMeanElementsNT

Parse an OMM `meanElements` section at the cursor's current position.
"""
function _parse_omm_mean_elements(xml::XML.Cursor, strict::Bool)
    comments = String[]
    epoch = nothing
    semi_major_axis = nothing
    mean_motion = nothing
    eccentricity = nothing
    inclination = nothing
    raan = nothing
    arg_of_pericenter = nothing
    mean_anomaly = nothing
    GM = nothing
    seen = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        i = findfirst(==(lt), _OMM_MEAN_ELEMENTS_FIELDS)
        isnothing(i) && throw(ArgumentError("Unknown OMM mean-elements field `$lt`."))
        seen & (UInt32(1) << i) != 0 &&
            throw(ArgumentError("Duplicate OMM mean-elements field `$lt`."))
        seen |= UInt32(1) << i

        if lt == "EPOCH"
            isempty(v) && throw(ArgumentError("OMM field `EPOCH` cannot be empty."))
            epoch = _parse_ndm_date(v)
        elseif lt == "SEMI_MAJOR_AXIS"
            semi_major_axis = _parse_omm_number(Float64, v, lt)
        elseif lt == "MEAN_MOTION"
            mean_motion = _parse_omm_number(Float64, v, lt)
        elseif lt == "ECCENTRICITY"
            eccentricity = _parse_omm_number(Float64, v, lt)
        elseif lt == "INCLINATION"
            inclination = _parse_omm_number(Float64, v, lt)
        elseif lt == "RA_OF_ASC_NODE"
            raan = _parse_omm_number(Float64, v, lt)
        elseif lt == "ARG_OF_PERICENTER"
            arg_of_pericenter = _parse_omm_number(Float64, v, lt)
        elseif lt == "MEAN_ANOMALY"
            mean_anomaly = _parse_omm_number(Float64, v, lt)
        else
            GM = _parse_omm_number(Float64, v, lt)
        end
    end

    isnothing(epoch) && throw(ArgumentError("OMM data is missing required field `EPOCH`."))
    (isnothing(semi_major_axis) == isnothing(mean_motion)) && throw(ArgumentError(
        "OMM data must contain exactly one of `SEMI_MAJOR_AXIS` and `MEAN_MOTION`."
    ))
    isnothing(eccentricity) && throw(ArgumentError(
        "OMM data is missing required field `ECCENTRICITY`."
    ))
    isnothing(inclination) && throw(ArgumentError(
        "OMM data is missing required field `INCLINATION`."
    ))
    isnothing(raan) && throw(ArgumentError(
        "OMM data is missing required field `RA_OF_ASC_NODE`."
    ))
    isnothing(arg_of_pericenter) && throw(ArgumentError(
        "OMM data is missing required field `ARG_OF_PERICENTER`."
    ))
    isnothing(mean_anomaly) && throw(ArgumentError(
        "OMM data is missing required field `MEAN_ANOMALY`."
    ))

    return _OmmMeanElementsNT((
        comments,
        epoch,
        semi_major_axis,
        mean_motion,
        eccentricity,
        inclination,
        raan,
        arg_of_pericenter,
        mean_anomaly,
        GM,
    ))
end

# Known fields of the OMM `spacecraftParameters` section.
const _OMM_SPACECRAFT_PARAMETERS_FIELDS = (
    "MASS",
    "SOLAR_RAD_AREA",
    "SOLAR_RAD_COEFF",
    "DRAG_AREA",
    "DRAG_COEFF",
)

# Concrete `NamedTuple` type returned by the `spacecraftParameters` section parsers. See
# the comment on `_OmmMeanElementsNT` for the rationale.
const _OmmSpacecraftParametersNT = @NamedTuple{
    spacecraft_parameters_comments::Vector{String},
    mass::Union{Nothing, Float64},
    solar_rad_area::Union{Nothing, Float64},
    solar_rad_coeff::Union{Nothing, Float64},
    drag_area::Union{Nothing, Float64},
    drag_coeff::Union{Nothing, Float64},
}

"""
    _empty_omm_spacecraft_parameters() -> _OmmSpacecraftParametersNT

Return default values for an omitted OMM `spacecraftParameters` section.
"""
function _empty_omm_spacecraft_parameters()
    return _OmmSpacecraftParametersNT((
        String[],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    ))
end

"""
    _parse_omm_spacecraft_parameters(xml::Cursor, strict::Bool) -> _OmmSpacecraftParametersNT

Parse an OMM `spacecraftParameters` section at the cursor's current position.
"""
function _parse_omm_spacecraft_parameters(xml::XML.Cursor, strict::Bool)
    comments = String[]
    mass = nothing
    solar_rad_area = nothing
    solar_rad_coeff = nothing
    drag_area = nothing
    drag_coeff = nothing
    seen = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        i = findfirst(==(lt), _OMM_SPACECRAFT_PARAMETERS_FIELDS)
        isnothing(i) && throw(ArgumentError("Unknown OMM spacecraft parameter `$lt`."))
        seen & (UInt32(1) << i) != 0 &&
            throw(ArgumentError("Duplicate OMM spacecraft parameter `$lt`."))
        seen |= UInt32(1) << i

        if lt == "MASS"
            mass = _parse_omm_number(Float64, v, lt)
        elseif lt == "SOLAR_RAD_AREA"
            solar_rad_area = _parse_omm_number(Float64, v, lt)
        elseif lt == "SOLAR_RAD_COEFF"
            solar_rad_coeff = _parse_omm_number(Float64, v, lt)
        elseif lt == "DRAG_AREA"
            drag_area = _parse_omm_number(Float64, v, lt)
        else
            drag_coeff = _parse_omm_number(Float64, v, lt)
        end
    end

    return _OmmSpacecraftParametersNT((
        comments,
        mass,
        solar_rad_area,
        solar_rad_coeff,
        drag_area,
        drag_coeff,
    ))
end

# Known fields of the OMM `tleParameters` section.
const _OMM_TLE_PARAMETERS_FIELDS = (
    "EPHEMERIS_TYPE",
    "CLASSIFICATION_TYPE",
    "NORAD_CAT_ID",
    "ELEMENT_SET_NO",
    "REV_AT_EPOCH",
    "BSTAR",
    "BTERM",
    "MEAN_MOTION_DOT",
    "MEAN_MOTION_DDOT",
    "AGOM",
)

# Concrete `NamedTuple` type returned by the `tleParameters` section parsers. See the
# comment on `_OmmMeanElementsNT` for the rationale.
const _OmmTleParametersNT = @NamedTuple{
    tle_parameters_comments::Vector{String},
    ephemeris_type::Union{Nothing, Int},
    classification_type::Union{Nothing, Char},
    norad_cat_id::Union{Nothing, Int},
    element_set_number::Union{Nothing, Int},
    rev_at_epoch::Union{Nothing, Int},
    bstar::Union{Nothing, Float64},
    bterm::Union{Nothing, Float64},
    mean_motion_dot::Union{Nothing, Float64},
    mean_motion_ddot::Union{Nothing, Float64},
    agom::Union{Nothing, Float64},
}

"""
    _empty_omm_tle_parameters() -> _OmmTleParametersNT

Return default values for an omitted OMM `tleParameters` section.
"""
function _empty_omm_tle_parameters()
    return _OmmTleParametersNT((
        String[],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    ))
end

"""
    _parse_omm_tle_parameters(xml::Cursor, strict::Bool, version::VersionNumber) -> _OmmTleParametersNT

Parse an OMM `tleParameters` section with schema `version` at the cursor's current
position.
"""
function _parse_omm_tle_parameters(xml::XML.Cursor, strict::Bool, version::VersionNumber)
    comments = String[]
    ephemeris_type = nothing
    classification_type = nothing
    norad_cat_id = nothing
    element_set_number = nothing
    rev_at_epoch = nothing
    bstar = nothing
    bterm = nothing
    mean_motion_dot = nothing
    mean_motion_ddot = nothing
    agom = nothing
    seen = UInt32(0)

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        i = findfirst(==(lt), _OMM_TLE_PARAMETERS_FIELDS)
        isnothing(i) && throw(ArgumentError("Unknown OMM TLE parameter `$lt`."))
        strict && version == v"2.0" && lt ∈ ("BTERM", "AGOM") && throw(ArgumentError(
            "OMM TLE parameter `$lt` is not valid in OMM version 2.0."
        ))
        seen & (UInt32(1) << i) != 0 &&
            throw(ArgumentError("Duplicate OMM TLE parameter `$lt`."))
        seen |= UInt32(1) << i

        if lt == "EPHEMERIS_TYPE"
            ephemeris_type = _parse_omm_number(Int, v, lt)
        elseif lt == "CLASSIFICATION_TYPE"
            length(v) == 1 || throw(ArgumentError(
                "OMM field `CLASSIFICATION_TYPE` must contain exactly one character."
            ))
            classification_type = only(v)
        elseif lt == "NORAD_CAT_ID"
            norad_cat_id = _parse_omm_number(Int, v, lt)
        elseif lt == "ELEMENT_SET_NO"
            element_set_number = _parse_omm_number(Int, v, lt)
        elseif lt == "REV_AT_EPOCH"
            rev_at_epoch = _parse_omm_number(Int, v, lt)
        elseif lt == "BSTAR"
            bstar = _parse_omm_number(Float64, v, lt)
        elseif lt == "BTERM"
            bterm = _parse_omm_number(Float64, v, lt)
        elseif lt == "MEAN_MOTION_DOT"
            mean_motion_dot = _parse_omm_number(Float64, v, lt)
        elseif lt == "MEAN_MOTION_DDOT"
            mean_motion_ddot = _parse_omm_number(Float64, v, lt)
        else
            agom = _parse_omm_number(Float64, v, lt)
        end
    end

    if strict && version == v"2.0"
        # In OMM version 2.0, `BSTAR` and `MEAN_MOTION_DDOT` are required fields, and
        # `BTERM` and `AGOM` do not exist.
        isnothing(bstar) && throw(ArgumentError(
            "OMM TLE parameters are missing required field `BSTAR`."
        ))
        isnothing(mean_motion_ddot) && throw(ArgumentError(
            "OMM TLE parameters are missing required field `MEAN_MOTION_DDOT`."
        ))
    else
        (isnothing(bstar) == isnothing(bterm)) && throw(ArgumentError(
            "OMM TLE parameters must contain exactly one of `BSTAR` and `BTERM`."
        ))
        (isnothing(mean_motion_ddot) == isnothing(agom)) && throw(ArgumentError(
            "OMM TLE parameters must contain exactly one of `MEAN_MOTION_DDOT` and `AGOM`."
        ))
    end

    isnothing(mean_motion_dot) && throw(ArgumentError(
        "OMM TLE parameters are missing required field `MEAN_MOTION_DOT`."
    ))

    return _OmmTleParametersNT((
        comments,
        ephemeris_type,
        classification_type,
        norad_cat_id,
        element_set_number,
        rev_at_epoch,
        bstar,
        bterm,
        mean_motion_dot,
        mean_motion_ddot,
        agom,
    ))
end

# Names of the 21 covariance matrix elements in the field order of `OmmCovarianceMatrix`.
const _OMM_COVARIANCE_ELEMENTS = (
    "CX_X",
    "CY_X",
    "CY_Y",
    "CZ_X",
    "CZ_Y",
    "CZ_Z",
    "CX_DOT_X",
    "CX_DOT_Y",
    "CX_DOT_Z",
    "CX_DOT_X_DOT",
    "CY_DOT_X",
    "CY_DOT_Y",
    "CY_DOT_Z",
    "CY_DOT_X_DOT",
    "CY_DOT_Y_DOT",
    "CZ_DOT_X",
    "CZ_DOT_Y",
    "CZ_DOT_Z",
    "CZ_DOT_X_DOT",
    "CZ_DOT_Y_DOT",
    "CZ_DOT_Z_DOT",
)

# Map covariance element names to their index in `_OMM_COVARIANCE_ELEMENTS`.
const _OMM_COVARIANCE_ELEMENT_INDICES = Dict{String, Int}(
    name => i for (i, name) in enumerate(_OMM_COVARIANCE_ELEMENTS)
)

"""
    _parse_omm_covariance_matrix(xml::Cursor, strict::Bool) -> OmmCovarianceMatrix

Parse an OMM `covarianceMatrix` section at the cursor's current position.
"""
function _parse_omm_covariance_matrix(xml::XML.Cursor, strict::Bool)
    comments = String[]
    cov_ref_frame::Union{Nothing, String} = nothing
    values = Vector{Float64}(undef, length(_OMM_COVARIANCE_ELEMENTS))
    filled = falses(length(_OMM_COVARIANCE_ELEMENTS))

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        if lt == "COV_REF_FRAME"
            !isnothing(cov_ref_frame) && throw(ArgumentError(
                "Duplicate OMM covariance element `$lt`."
            ))
            cov_ref_frame = v
        else
            i = get(_OMM_COVARIANCE_ELEMENT_INDICES, lt, 0)
            i == 0 && throw(ArgumentError("Unknown OMM covariance element `$lt`."))
            filled[i] && throw(ArgumentError("Duplicate OMM covariance element `$lt`."))
            filled[i] = true
            values[i] = _parse_omm_number(Float64, v, lt)
        end
    end

    for (i, name) in enumerate(_OMM_COVARIANCE_ELEMENTS)
        filled[i] || throw(ArgumentError(
            "OMM covariance matrix is missing required element `$name`."
        ))
    end

    return OmmCovarianceMatrix(
        comments,
        cov_ref_frame,
        NTuple{length(_OMM_COVARIANCE_ELEMENTS), Float64}(values)...
    )
end

"""
    _parse_omm_user_defined_parameters(
        xml::Cursor,
        strict::Bool
    ) -> Vector{Pair{String,String}}

Parse an OMM `userDefinedParameters` section at the cursor's current position.
"""
function _parse_omm_user_defined_parameters(xml::XML.Cursor, strict::Bool)
    parameters = Pair{String, String}[]
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        lt == "USER_DEFINED" ||
            throw(ArgumentError("Unknown user-defined parameter element `$lt`."))
        key = get(node, "parameter", nothing)
        isnothing(key) && throw(ArgumentError(
            "OMM `USER_DEFINED` element is missing required attribute `parameter`."
        ))
        push!(parameters, String(key) => _omm_scalar_value(node))
    end
    return parameters
end
