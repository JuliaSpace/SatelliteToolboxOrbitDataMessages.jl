## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using XML input.
#
############################################################################################

"""
    _xml_omm__parse(xml::Cursor, strict::Bool) -> Union{Nothing, NamedTuple}

Parse the first Orbit Mean-Elements Message (OMM) in the XML document at the `Cursor`
`xml`, returning the container `(; version, header, metadata, data)` with the raw field
values. If the document does not contain an OMM message, `nothing` is returned.
"""
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
`(; version, header, metadata, data)` with the raw field values. The mandatory fields are
checked afterwards by [`_omm_check_mandatory_fields`](@ref).
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
    isnothing(version_attribute) && throw(ArgumentError(
        "The OMM element is missing the required `version` attribute."
    ))

    version = VersionNumber(version_attribute)

    version ∉ (v"2.0.0", v"3.0.0") &&
        throw(ArgumentError("Unsupported OMM version: $version."))

    header = nothing
    segment = nothing
    element_tags = String[]
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        push!(element_tags, lt)
        if lt == "header" && isnothing(header)
            header = _xml_omm__parse_header(node, strict)
        elseif lt == "body" && isnothing(segment)
            segment = _xml_omm__parse_body(node, strict)
        else
            skip_element!(node)
        end
    end
    element_tags == ["header", "body"] || throw(ArgumentError(
        "The OMM element must contain exactly one `header` followed by one `body`."
    ))

    metadata, data = segment

    return (; version, header, metadata, data)
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
    result = ""
    XML.@for_each_child xml node begin
        if nodetype(node) === XML.Text || nodetype(node) === XML.CData
            result *= String(value(node))
        elseif nodetype(node) === Element
            skip_element!(node)
        end
    end
    return String(strip(result))
end

"""
    _xml_omm__parse_number(::Type{T}, v::AbstractString, field::AbstractString) where T <: Number -> T

Parse the string `v` as a number of type `T`, throwing an `ArgumentError` that names the
OMM `field` if the value is not a valid number.
"""
function _xml_omm__parse_number(
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

"""
    _xml_omm__parse_header(xml::Cursor, strict::Bool) -> NamedTuple

Parse the header of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning a named tuple with the raw field values. Fields that are absent
are set to `nothing`; the mandatory fields are checked afterwards by
[`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_header(xml::XML.Cursor, strict::Bool)
    comments       = String[]
    classification = nothing
    creation_date  = nothing
    originator     = nothing
    message_id     = nothing
    seen           = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)

        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        lt ∉ (
            "CLASSIFICATION",
            "CREATION_DATE",
            "ORIGINATOR",
            "MESSAGE_ID",
        ) && throw(ArgumentError("Unknown OMM header field `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM header field `$lt`."))
        push!(seen, lt)

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

    # `CREATION_DATE` is checked here instead of in `_omm_check_mandatory_fields` because
    # its presence requirement is relaxed when parsing leniently, allowing real-world files
    # with an omitted creation date to be processed.
    strict && isnothing(creation_date) && throw(ArgumentError(
        "OMM header is missing required field `CREATION_DATE`."
    ))

    return (;
        comments,
        classification,
        creation_date,
        originator,
        message_id,
    )
end

# == Body Parsing ==========================================================================

"""
    _xml_omm__parse_body(xml::Cursor, strict::Bool) -> Tuple{NamedTuple, NamedTuple}

Parse the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning named tuples with the raw field values of the metadata and data
sections of its single segment.
"""
function _xml_omm__parse_body(xml::XML.Cursor, strict::Bool)
    segment = nothing
    segment_count = 0
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        _xml_omm__tag(node, strict) == "segment" ||
            throw(ArgumentError("Unknown OMM body element."))
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
    _xml_omm__parse_segment(xml::Cursor, strict::Bool) -> Tuple{NamedTuple, NamedTuple}

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation, returning named tuples with the raw field values of its metadata and data
sections.
"""
function _xml_omm__parse_segment(xml::XML.Cursor, strict::Bool)
    metadata = nothing
    data = nothing
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        lt ∈ ("metadata", "data") ||
            throw(ArgumentError("Unknown OMM segment element."))
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
    _xml_omm__parse_metadata(xml::Cursor, strict::Bool) -> NamedTuple

Parse the metadata of the segment body of an Orbit Mean-Elements Message (OMM) from a
`Cursor` `xml` representation, returning a named tuple with the raw field values. Fields
that are absent are set to `nothing`; the mandatory fields are checked afterwards by
[`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_metadata(xml::XML.Cursor, strict::Bool)
    comments            = String[]
    object_name         = nothing
    object_id           = nothing
    center_name         = nothing
    ref_frame           = nothing
    ref_frame_epoch     = nothing
    time_system         = nothing
    mean_element_theory = nothing
    seen                = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)

        if lt == "COMMENT"
            push!(comments, v)
            continue
        end

        lt ∉ (
            "OBJECT_NAME",
            "OBJECT_ID",
            "CENTER_NAME",
            "REF_FRAME",
            "REF_FRAME_EPOCH",
            "TIME_SYSTEM",
            "MEAN_ELEMENT_THEORY",
        ) && throw(ArgumentError("Unknown OMM metadata field `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM metadata field `$lt`."))
        push!(seen, lt)

        if lt == "OBJECT_NAME"
            object_name = v
        elseif lt == "OBJECT_ID"
            object_id = v
        elseif lt == "CENTER_NAME"
            center_name = v
        elseif lt == "REF_FRAME"
            ref_frame = v
        elseif lt == "REF_FRAME_EPOCH"
            isempty(v) && throw(ArgumentError(
                "OMM field `REF_FRAME_EPOCH` cannot be empty."
            ))
            ref_frame_epoch = _parse_ndm_date(v)
        elseif lt == "TIME_SYSTEM"
            time_system = v
        elseif lt == "MEAN_ELEMENT_THEORY"
            mean_element_theory = v
        end
    end

    return (;
        comments,
        object_name,
        object_id,
        center_name,
        ref_frame,
        ref_frame_epoch,
        time_system,
        mean_element_theory,
    )
end

"""
    _xml_omm__parse_data(xml::Cursor, strict::Bool) -> NamedTuple

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) from a
`Cursor` `xml` representation, returning a named tuple with the raw field values of all
data subsections. Fields that are absent are set to `nothing`; the mandatory fields are
checked afterwards by [`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_data(xml::XML.Cursor, strict::Bool)
    data_comments = String[]
    mean_elements = nothing
    spacecraft_parameters = nothing
    tle_parameters = nothing
    covariance_matrix = nothing
    user_defined_parameters = nothing
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
            mean_elements = _xml_omm__parse_mean_elements(node, strict)
        elseif lt == "spacecraftParameters"
            spacecraft_parameters = _xml_omm__parse_spacecraft_parameters(node, strict)
        elseif lt == "tleParameters"
            tle_parameters = _xml_omm__parse_tle_parameters(node, strict)
        elseif lt == "covarianceMatrix"
            covariance_matrix = _xml_omm__parse_covariance_matrix(node, strict)
        else
            user_defined_parameters = _xml_omm__parse_user_defined_parameters(node, strict)
        end
    end

    mean_elements = something(mean_elements, _xml_omm__empty_mean_elements())
    spacecraft_parameters = something(
        spacecraft_parameters,
        _xml_omm__empty_spacecraft_parameters()
    )
    tle_parameters = something(tle_parameters, _xml_omm__empty_tle_parameters())

    return (;
        comments = data_comments,
        mean_elements...,
        spacecraft_parameters...,
        tle_parameters...,
        covariance_matrix,
        user_defined_parameters,
    )
end

"""
    _xml_omm__empty_mean_elements() -> NamedTuple

Return default values for an omitted OMM `meanElements` section.
"""
function _xml_omm__empty_mean_elements()
    return (
        mean_elements_comments = String[],
        epoch = nothing,
        semi_major_axis = nothing,
        mean_motion = nothing,
        eccentricity = nothing,
        inclination = nothing,
        raan = nothing,
        arg_of_pericenter = nothing,
        mean_anomaly = nothing,
        GM = nothing,
    )
end

"""
    _xml_omm__parse_mean_elements(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM `meanElements` section at the cursor's current position.
"""
function _xml_omm__parse_mean_elements(xml::XML.Cursor, strict::Bool)
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
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end
        lt ∉ (
            "EPOCH",
            "SEMI_MAJOR_AXIS",
            "MEAN_MOTION",
            "ECCENTRICITY",
            "INCLINATION",
            "RA_OF_ASC_NODE",
            "ARG_OF_PERICENTER",
            "MEAN_ANOMALY",
            "GM",
        ) && throw(ArgumentError("Unknown OMM mean-elements field `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM mean-elements field `$lt`."))
        push!(seen, lt)

        if lt == "EPOCH"
            isempty(v) && throw(ArgumentError("OMM field `EPOCH` cannot be empty."))
            epoch = _parse_ndm_date(v)
        elseif lt == "SEMI_MAJOR_AXIS"
            semi_major_axis = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "MEAN_MOTION"
            mean_motion = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "ECCENTRICITY"
            eccentricity = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "INCLINATION"
            inclination = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "RA_OF_ASC_NODE"
            raan = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "ARG_OF_PERICENTER"
            arg_of_pericenter = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "MEAN_ANOMALY"
            mean_anomaly = _xml_omm__parse_number(Float64, v, lt)
        else
            GM = _xml_omm__parse_number(Float64, v, lt)
        end
    end

    return (
        mean_elements_comments = comments,
        epoch = epoch,
        semi_major_axis = semi_major_axis,
        mean_motion = mean_motion,
        eccentricity = eccentricity,
        inclination = inclination,
        raan = raan,
        arg_of_pericenter = arg_of_pericenter,
        mean_anomaly = mean_anomaly,
        GM = GM,
    )
end

"""
    _xml_omm__empty_spacecraft_parameters() -> NamedTuple

Return default values for an omitted OMM `spacecraftParameters` section.
"""
function _xml_omm__empty_spacecraft_parameters()
    return (
        spacecraft_parameters_comments = String[],
        mass = nothing,
        solar_rad_area = nothing,
        solar_rad_coeff = nothing,
        drag_area = nothing,
        drag_coeff = nothing,
    )
end

"""
    _xml_omm__parse_spacecraft_parameters(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM `spacecraftParameters` section at the cursor's current position.
"""
function _xml_omm__parse_spacecraft_parameters(xml::XML.Cursor, strict::Bool)
    comments = String[]
    mass = nothing
    solar_rad_area = nothing
    solar_rad_coeff = nothing
    drag_area = nothing
    drag_coeff = nothing
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end
        lt ∉ ("MASS", "SOLAR_RAD_AREA", "SOLAR_RAD_COEFF", "DRAG_AREA", "DRAG_COEFF") &&
            throw(ArgumentError("Unknown OMM spacecraft parameter `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM spacecraft parameter `$lt`."))
        push!(seen, lt)

        if lt == "MASS"
            mass = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "SOLAR_RAD_AREA"
            solar_rad_area = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "SOLAR_RAD_COEFF"
            solar_rad_coeff = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "DRAG_AREA"
            drag_area = _xml_omm__parse_number(Float64, v, lt)
        else
            drag_coeff = _xml_omm__parse_number(Float64, v, lt)
        end
    end

    return (
        spacecraft_parameters_comments = comments,
        mass = mass,
        solar_rad_area = solar_rad_area,
        solar_rad_coeff = solar_rad_coeff,
        drag_area = drag_area,
        drag_coeff = drag_coeff,
    )
end

"""
    _xml_omm__empty_tle_parameters() -> NamedTuple

Return default values for an omitted OMM `tleParameters` section.
"""
function _xml_omm__empty_tle_parameters()
    return (
        tle_parameters_comments = String[],
        ephemeris_type = nothing,
        classification_type = nothing,
        norad_cat_id = nothing,
        element_set_number = nothing,
        rev_at_epoch = nothing,
        bstar = nothing,
        bterm = nothing,
        mean_motion_dot = nothing,
        mean_motion_ddot = nothing,
        agom = nothing,
    )
end

"""
    _xml_omm__parse_tle_parameters(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM `tleParameters` section at the cursor's current position.
"""
function _xml_omm__parse_tle_parameters(xml::XML.Cursor, strict::Bool)
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
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end
        lt ∉ (
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
        ) && throw(ArgumentError("Unknown OMM TLE parameter `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM TLE parameter `$lt`."))
        push!(seen, lt)

        if lt == "EPHEMERIS_TYPE"
            ephemeris_type = _xml_omm__parse_number(Int, v, lt)
        elseif lt == "CLASSIFICATION_TYPE"
            length(v) == 1 || throw(ArgumentError(
                "OMM field `CLASSIFICATION_TYPE` must contain exactly one character."
            ))
            classification_type = only(v)
        elseif lt == "NORAD_CAT_ID"
            norad_cat_id = _xml_omm__parse_number(Int, v, lt)
        elseif lt == "ELEMENT_SET_NO"
            element_set_number = _xml_omm__parse_number(Int, v, lt)
        elseif lt == "REV_AT_EPOCH"
            rev_at_epoch = _xml_omm__parse_number(Int, v, lt)
        elseif lt == "BSTAR"
            bstar = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "BTERM"
            bterm = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "MEAN_MOTION_DOT"
            mean_motion_dot = _xml_omm__parse_number(Float64, v, lt)
        elseif lt == "MEAN_MOTION_DDOT"
            mean_motion_ddot = _xml_omm__parse_number(Float64, v, lt)
        else
            agom = _xml_omm__parse_number(Float64, v, lt)
        end
    end

    return (
        tle_parameters_comments = comments,
        ephemeris_type = ephemeris_type,
        classification_type = classification_type,
        norad_cat_id = norad_cat_id,
        element_set_number = element_set_number,
        rev_at_epoch = rev_at_epoch,
        bstar = bstar,
        bterm = bterm,
        mean_motion_dot = mean_motion_dot,
        mean_motion_ddot = mean_motion_ddot,
        agom = agom,
    )
end

# CCSDS keywords of the 21 elements of the OMM covariance matrix, in the field order of
# `OmmCovarianceMatrix`.
const _XML_OMM__COVARIANCE_ELEMENTS = (
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

"""
    _xml_omm__parse_covariance_matrix(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM `covarianceMatrix` section at the cursor's current position, returning a
named tuple with the raw field values. Elements that are absent are set to `nothing`; the
mandatory elements are checked afterwards by [`_omm_check_mandatory_fields`](@ref).
"""
function _xml_omm__parse_covariance_matrix(xml::XML.Cursor, strict::Bool)
    comments = String[]
    cov_ref_frame = nothing
    values = Dict{String, Float64}()
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _xml_omm__tag(node, strict)
        v = _xml_omm__scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end
        lt in seen && throw(ArgumentError("Duplicate OMM covariance element `$lt`."))
        push!(seen, lt)

        if lt == "COV_REF_FRAME"
            cov_ref_frame = v
        elseif lt in _XML_OMM__COVARIANCE_ELEMENTS
            values[lt] = _xml_omm__parse_number(Float64, v, lt)
        else
            throw(ArgumentError("Unknown OMM covariance element `$lt`."))
        end
    end

    return (;
        comments,
        cov_ref_frame,
        (
            Symbol(lowercase(name)) => get(values, name, nothing)
            for name in _XML_OMM__COVARIANCE_ELEMENTS
        )...,
    )
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
        lt == "USER_DEFINED" ||
            throw(ArgumentError("Unknown user-defined parameter element `$lt`."))
        key = get(node, "parameter", nothing)
        isnothing(key) && throw(ArgumentError(
            "OMM `USER_DEFINED` element is missing required attribute `parameter`."
        ))
        push!(parameters, String(key) => _xml_omm__scalar_value(node))
    end
    return parameters
end
