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
    for node in xml
        nodetype(node) === Element || continue
        t = _omm_tag(node, strict)
        t == "omm" && return _parse_omm(node, strict)
    end

    return nothing
end

"""
    parse_omms(str::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) string `str` and return the parsed
messages. The input format must be XML.

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
    omms = OrbitMeanElementsMessage[]
    root = next!(xml)
    while !isnothing(root) && nodetype(root) !== Element
        root = next!(xml)
    end
    isnothing(root) && throw(ArgumentError("The XML document has no root element."))
    t = _omm_tag(root, strict)

    if t == "ndm"
        XML.@for_each_child root node begin
            nodetype(node) === Element || continue
            lt = _omm_tag(node, strict)

            if lt == "omm"
                push!(omms, _parse_omm(node, strict))
            elseif lt == "opm"
                @warn "We do not support Orbit Parameter Messages (OPM) yet."
            elseif lt == "oem"
                @warn "We do not support Orbit Ephemeris Messages (OEM) yet."
            elseif lt == "ocm"
                @warn "We do not support Orbit Comprehensive Messages (OCM) yet."
            end
        end

        return omms

    elseif t == "omm"
        push!(omms, _parse_omm(root, strict))
        return omms
    elseif t == "opm"
        @warn "We do not support Orbit Parameter Messages (OPM) yet."
        return omms
    elseif t == "oem"
        @warn "We do not support Orbit Ephemeris Messages (OEM) yet."
        return omms
    elseif t == "ocm"
        @warn "We do not support Orbit Comprehensive Messages (OCM) yet."
        return omms
    else
        return throw(ArgumentError("The root tag `$t` is not recognized."))
    end

    return omms
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

"""
    _omm_tag(node::Cursor, strict::Bool) -> Union{String, Nothing}

Return the canonical OMM tag for `node`, matching case-insensitively unless `strict` is
`true`.
"""
function _omm_tag(node::XML.Cursor, strict::Bool)
    node_tag = tag(node)
    (strict || isnothing(node_tag)) && return node_tag

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
        "The OMM element is missing the required `id = CCSDS_OMM_VERSION` attribute."
    ))

    version_attribute = get(xml, "version", nothing)
    isnothing(version_attribute) && throw(ArgumentError(
        "The OMM element is missing the required `version` attribute."
    ))

    version = VersionNumber(version_attribute)

    version ∉ (v"2.0.0", v"3.0.0") &&
        throw(ArgumentError("Unsupported OMM version: $version."))

    header = nothing
    body = nothing
    element_tags = String[]
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        push!(element_tags, lt)
        if lt == "header" && isnothing(header)
            header = _parse_omm_header(node, strict)
        elseif lt == "body" && isnothing(body)
            body = _parse_omm_body(node, strict)
        else
            skip_element!(node)
        end
    end
    element_tags == ["header", "body"] || throw(ArgumentError(
        "The OMM element must contain exactly one `header` followed by one `body`."
    ))

    return OrbitMeanElementsMessage(version, header, body)
end

"""
    _omm_scalar_value(xml::Cursor) -> String

Read the text or CDATA value of the current OMM scalar element while advancing the cursor
past that element. Non-value child nodes are ignored.
"""
function _omm_scalar_value(xml::XML.Cursor)
    result = ""
    XML.@for_each_child xml node begin
        if nodetype(node) === XML.Text || nodetype(node) === XML.CData
            isempty(result) && (result = String(value(node)))
        elseif nodetype(node) === Element
            skip_element!(node)
        end
    end
    return result
end

# == Header Parsing ========================================================================

"""
    _parse_omm_header(xml::Cursor, strict::Bool) -> OmmHeader

Parse the header of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation.
"""
function _parse_omm_header(xml::XML.Cursor, strict::Bool)
    comments       = String[]
    classification = nothing
    creation_date  = nothing
    originator     = nothing
    message_id     = nothing
    seen           = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)

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
    _parse_omm_body(xml::Cursor, strict::Bool) -> OmmBody

Parse the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation.
"""
function _parse_omm_body(xml::XML.Cursor, strict::Bool)
    segment = nothing
    segment_count = 0
    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        _omm_tag(node, strict) == "segment" ||
            throw(ArgumentError("Unknown OMM body element."))
        segment_count += 1
        if segment_count == 1
            segment = _parse_omm_segment(node, strict)
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
    _parse_omm_segment(xml::Cursor, strict::Bool) -> OmmSegment

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) from a `Cursor` `xml`
representation.
"""
function _parse_omm_segment(xml::XML.Cursor, strict::Bool)
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
            data = _parse_omm_data(node, strict)
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
    seen                = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)

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

"""
    _parse_omm_data(xml::Cursor, strict::Bool) -> OmmData

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) from a
`Cursor` `xml` representation.
"""
function _parse_omm_data(xml::XML.Cursor, strict::Bool)
    data_comments = String[]
    mean_elements = nothing
    spacecraft_parameters = nothing
    tle_parameters = nothing
    covariance_matrix = nothing
    user_defined_parameters = nothing
    seen_sections = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        if lt == "COMMENT"
            push!(data_comments, _omm_scalar_value(node))
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
            mean_elements = _parse_omm_mean_elements(node, strict)
        elseif lt == "spacecraftParameters"
            spacecraft_parameters = _parse_omm_spacecraft_parameters(node, strict)
        elseif lt == "tleParameters"
            tle_parameters = _parse_omm_tle_parameters(node, strict)
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

"""
    _parse_omm_mean_elements(xml::Cursor, strict::Bool) -> NamedTuple

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
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
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
            semi_major_axis = parse(Float64, v)
        elseif lt == "MEAN_MOTION"
            mean_motion = parse(Float64, v)
        elseif lt == "ECCENTRICITY"
            eccentricity = parse(Float64, v)
        elseif lt == "INCLINATION"
            inclination = parse(Float64, v)
        elseif lt == "RA_OF_ASC_NODE"
            raan = parse(Float64, v)
        elseif lt == "ARG_OF_PERICENTER"
            arg_of_pericenter = parse(Float64, v)
        elseif lt == "MEAN_ANOMALY"
            mean_anomaly = parse(Float64, v)
        else
            GM = parse(Float64, v)
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
    _empty_omm_spacecraft_parameters() -> NamedTuple

Return default values for an omitted OMM `spacecraftParameters` section.
"""
function _empty_omm_spacecraft_parameters()
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
    _parse_omm_spacecraft_parameters(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM `spacecraftParameters` section at the cursor's current position.
"""
function _parse_omm_spacecraft_parameters(xml::XML.Cursor, strict::Bool)
    result = _empty_omm_spacecraft_parameters()
    comments = result.spacecraft_parameters_comments
    mass = nothing
    solar_rad_area = nothing
    solar_rad_coeff = nothing
    drag_area = nothing
    drag_coeff = nothing
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end
        lt ∉ ("MASS", "SOLAR_RAD_AREA", "SOLAR_RAD_COEFF", "DRAG_AREA", "DRAG_COEFF") &&
            throw(ArgumentError("Unknown OMM spacecraft parameter `$lt`."))
        lt in seen && throw(ArgumentError("Duplicate OMM spacecraft parameter `$lt`."))
        push!(seen, lt)

        if lt == "MASS"
            mass = parse(Float64, v)
        elseif lt == "SOLAR_RAD_AREA"
            solar_rad_area = parse(Float64, v)
        elseif lt == "SOLAR_RAD_COEFF"
            solar_rad_coeff = parse(Float64, v)
        elseif lt == "DRAG_AREA"
            drag_area = parse(Float64, v)
        else
            drag_coeff = parse(Float64, v)
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
    _empty_omm_tle_parameters() -> NamedTuple

Return default values for an omitted OMM `tleParameters` section.
"""
function _empty_omm_tle_parameters()
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
    _parse_omm_tle_parameters(xml::Cursor, strict::Bool) -> NamedTuple

Parse an OMM `tleParameters` section at the cursor's current position.
"""
function _parse_omm_tle_parameters(xml::XML.Cursor, strict::Bool)
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
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
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
            ephemeris_type = parse(Int, v)
        elseif lt == "CLASSIFICATION_TYPE"
            length(v) == 1 || throw(ArgumentError(
                "OMM field `CLASSIFICATION_TYPE` must contain exactly one character."
            ))
            classification_type = only(v)
        elseif lt == "NORAD_CAT_ID"
            norad_cat_id = parse(Int, v)
        elseif lt == "ELEMENT_SET_NO"
            element_set_number = parse(Int, v)
        elseif lt == "REV_AT_EPOCH"
            rev_at_epoch = parse(Int, v)
        elseif lt == "BSTAR"
            bstar = parse(Float64, v)
        elseif lt == "BTERM"
            bterm = parse(Float64, v)
        elseif lt == "MEAN_MOTION_DOT"
            mean_motion_dot = parse(Float64, v)
        elseif lt == "MEAN_MOTION_DDOT"
            mean_motion_ddot = parse(Float64, v)
        else
            agom = parse(Float64, v)
        end
    end

    (isnothing(bstar) == isnothing(bterm)) && throw(ArgumentError(
        "OMM TLE parameters must contain exactly one of `BSTAR` and `BTERM`."
    ))
    isnothing(mean_motion_dot) && throw(ArgumentError(
        "OMM TLE parameters are missing required field `MEAN_MOTION_DOT`."
    ))
    (isnothing(mean_motion_ddot) == isnothing(agom)) && throw(ArgumentError(
        "OMM TLE parameters must contain exactly one of `MEAN_MOTION_DDOT` and `AGOM`."
    ))

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

"""
    _parse_omm_covariance_matrix(xml::Cursor, strict::Bool) -> OmmCovarianceMatrix

Parse an OMM `covarianceMatrix` section at the cursor's current position.
"""
function _parse_omm_covariance_matrix(xml::XML.Cursor, strict::Bool)
    comments = String[]
    cov_ref_frame = nothing
    names = (
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
    values = Dict{String, Union{Nothing, Float64}}(name => nothing for name in names)
    seen = Set{String}()

    XML.@for_each_child xml node begin
        nodetype(node) === Element || continue
        lt = _omm_tag(node, strict)
        v = _omm_scalar_value(node)
        if lt == "COMMENT"
            push!(comments, v)
            continue
        end
        lt in seen && throw(ArgumentError("Duplicate OMM covariance element `$lt`."))
        push!(seen, lt)

        if lt == "COV_REF_FRAME"
            cov_ref_frame = v
        elseif haskey(values, lt)
            values[lt] = parse(Float64, v)
        else
            throw(ArgumentError("Unknown OMM covariance element `$lt`."))
        end
    end

    for name in names
        isnothing(values[name]) && throw(ArgumentError(
            "OMM covariance matrix is missing required element `$name`."
        ))
    end

    return OmmCovarianceMatrix(
        comments,
        cov_ref_frame,
        (values[name] for name in names)...
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
