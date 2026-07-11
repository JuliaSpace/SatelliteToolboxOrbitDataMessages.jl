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

    parse_omm(xml::LazyNode; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml` and return the parsed
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
    xml = parse(String(str), LazyNode)
    return parse_omm(xml; strict)
end

function parse_omm(xml::LazyNode; strict::Bool = true)
    for node in xml
        t = _omm_tag(node, strict)
        t == "omm" && return _parse_omm(node, strict)
    end

    return nothing
end

"""
    parse_omms(str::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) string `str` and return the parsed
messages. The input format must be XML.

    parse_omms(xml::LazyNode; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) from a `LazyNode` `xml` and return the
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
    xml = parse(String(str), LazyNode)
    return parse_omms(xml; strict)
end

function parse_omms(xml::LazyNode; strict::Bool = true)
    omms = OrbitMeanElementsMessage[]
    root = children(xml)[end]
    t    = _omm_tag(root, strict)

    if t == "ndm"
        for node in children(root)
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
    _omm_tag(node::LazyNode, strict::Bool) -> Union{String, Nothing}

Return the canonical OMM tag for `node`, matching case-insensitively unless `strict` is
`true`.
"""
function _omm_tag(node::LazyNode, strict::Bool)
    node_tag = tag(node)
    (strict || isnothing(node_tag)) && return node_tag

    lowercase_tag = lowercase(node_tag)
    return get(_OMM_STRUCTURAL_TAGS, lowercase_tag, uppercase(node_tag))
end

"""
    _parse_omm(xml::LazyNode) -> OrbitMeanElementsMessage

Parse an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml` representation.
"""
function _parse_omm(xml::LazyNode, strict::Bool)
    _omm_tag(xml, strict) != "omm" && throw(
        ArgumentError("The provided XML does not contain an OMM element.")
    )

    # Extract the version attribute.
    att = attributes(xml)

    valid_id = haskey(att, "id") && (
        strict ? att["id"] == "CCSDS_OMM_VERS" :
        lowercase(att["id"]) == "ccsds_omm_vers"
    )
    !valid_id && throw(ArgumentError(
        "The OMM element is missing the required `id = CCSDS_OMM_VERSION` attribute."
    ))

    !haskey(att, "version") && throw(ArgumentError(
        "The OMM element is missing the required `version` attribute."
    ))

    version = VersionNumber(att["version"])

    version ∉ (v"2.0.0", v"3.0.0") &&
        throw(ArgumentError("Unsupported OMM version: $version."))

    nodes = children(xml)
    map(node -> _omm_tag(node, strict), nodes) == ["header", "body"] ||
        throw(ArgumentError(
        "The OMM element must contain exactly one `header` followed by one `body`."
        ))

    # == Parse Header ======================================================================

    header_id = findfirst(n -> _omm_tag(n, strict) == "header", nodes)

    isnothing(header_id) && throw(ArgumentError("The OMM element is missing the header."))

    header = _parse_omm_header(nodes[header_id], strict)

    # == Parse Body ========================================================================

    body_id = findfirst(n -> _omm_tag(n, strict) == "body", nodes)

    isnothing(body_id) && throw(ArgumentError("The OMM element is missing the body."))

    body = _parse_omm_body(nodes[body_id], strict)

    return OrbitMeanElementsMessage(version, header, body)
end

# == Header Parsing ========================================================================

"""
    _parse_omm_header(xml::LazyNode) -> OmmHeader

Parse the header of an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml`
representation.
"""
function _parse_omm_header(xml::LazyNode, strict::Bool)
    comments       = String[]
    classification = nothing
    creation_date  = nothing
    originator     = nothing
    message_id     = nothing
    seen           = Set{String}()

    for node in children(xml)
        lt = _omm_tag(node, strict)
        nc = children(node)
        v  = isempty(nc) ? "" : value(first(nc))

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
    _parse_omm_body(xml::LazyNode) -> OmmBody

Parse the body of an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml`
representation.
"""
function _parse_omm_body(xml::LazyNode, strict::Bool)
    ch = children(xml)
    any(n -> _omm_tag(n, strict) != "segment", ch) &&
        throw(ArgumentError("Unknown OMM body element."))
    segment_ids = findall(n -> _omm_tag(n, strict) == "segment", ch)

    isempty(segment_ids) && throw(ArgumentError("The OMM body is missing the segment."))
    length(segment_ids) > 1 && throw(ArgumentError(
        "The OMM body contains multiple segments, which is not supported."
    ))

    segment = _parse_omm_segment(ch[first(segment_ids)], strict)

    return OmmBody(segment)
end

# -- Body Segment Parsing ------------------------------------------------------------------

"""
    _parse_omm_segment(xml::LazyNode) -> OmmSegment

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml`
representation.
"""
function _parse_omm_segment(xml::LazyNode, strict::Bool)
    ch = children(xml)

    # Find the metadata node.
    any(n -> _omm_tag(n, strict) ∉ ("metadata", "data"), ch) &&
        throw(ArgumentError("Unknown OMM segment element."))
    count(n -> _omm_tag(n, strict) == "metadata", ch) > 1 &&
        throw(ArgumentError("The OMM segment contains duplicate metadata sections."))
    count(n -> _omm_tag(n, strict) == "data", ch) > 1 &&
        throw(ArgumentError("The OMM segment contains duplicate data sections."))

    metadata_id = findfirst(n -> _omm_tag(n, strict) == "metadata", ch)
    isnothing(metadata_id) && throw(ArgumentError(
        "The OMM segment is missing the metadata section."
    ))
    metadata_nodes = ch[metadata_id]

    # Find the data node.
    data_id = findfirst(n -> _omm_tag(n, strict) == "data", ch)
    isnothing(data_id) && throw(ArgumentError(
        "The OMM segment is missing the data section."
    ))
    data_nodes = ch[data_id]

    # == Parse Metadata ====================================================================

    metadata = _parse_omm_metadata(metadata_nodes, strict)

    # == Parse Data ========================================================================

    data = _parse_omm_data(data_nodes, strict)

    return OmmSegment(metadata, data)
end

"""
    _parse_omm_metadata(xml::LazyNode) -> OmmMetadata

Parse the metadata of the segment body of an Orbit Mean-Elements Message (OMM) from a
`LazyNode` `xml` representation.
"""
function _parse_omm_metadata(xml::LazyNode, strict::Bool)
    ch = children(xml)

    comments            = String[]
    object_name         = nothing
    object_id           = nothing
    center_name         = nothing
    ref_frame           = nothing
    ref_frame_epoch     = nothing
    time_system         = nothing
    mean_element_theory = nothing
    seen                = Set{String}()

    for node in ch
        lt = _omm_tag(node, strict)
        nc = children(node)
        v  = isempty(nc) ? "" : value(first(nc))

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
    _parse_omm_data(xml::LazyNode) -> OmmData

Parse the data of the segment body of an Orbit Mean-Elements Message (OMM) from a
`LazyNode` `xml` representation.
"""
function _parse_omm_data(xml::LazyNode, strict::Bool)
    ch = children(xml)

    data_comments                = String[]
    mean_elements_nodes          = nothing
    spacecraft_parameters_nodes  = nothing
    tle_parameters_nodes         = nothing
    covariance_matrix_nodes      = nothing
    user_defined_parameter_nodes = nothing
    seen_sections                = Set{String}()

    for node in ch
        lt = _omm_tag(node, strict)
        nc = children(node)

        if lt == "COMMENT"
            v  = isempty(nc) ? "" : value(first(nc))
            push!(data_comments, v)
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
            mean_elements_nodes = nc
        elseif lt == "spacecraftParameters"
            spacecraft_parameters_nodes = nc
        elseif lt == "tleParameters"
            tle_parameters_nodes = nc
        elseif lt == "covarianceMatrix"
            covariance_matrix_nodes = nc
        elseif lt == "userDefinedParameters"
            user_defined_parameter_nodes = nc
        end
    end

    # == Parse Mean Elements ===============================================================

    isnothing(mean_elements_nodes) && throw(ArgumentError(
        "The OMM data is missing the required section `meanElements`."
    ))

    epoch             = nothing
    mean_elements_comments = String[]
    semi_major_axis   = nothing
    mean_motion       = nothing
    eccentricity      = nothing
    inclination       = nothing
    raan              = nothing
    arg_of_pericenter = nothing
    mean_anomaly      = nothing
    GM                = nothing
    seen              = Set{String}()

    for node in mean_elements_nodes
        lt = _omm_tag(node, strict)
        nc = children(node)
        v  = isempty(nc) ? "" : value(first(nc))

        if lt == "COMMENT"
            push!(mean_elements_comments, v)
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
        elseif lt == "GM"
            GM = parse(Float64, v)
        end
    end

    # Check if all required fields are present.
    isnothing(epoch) && throw(ArgumentError(
        "OMM data is missing required field `EPOCH`."
    ))

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

    # == Parse Spacecraft Parameters =======================================================

    spacecraft_parameters_comments = String[]
    mass                            = nothing
    solar_rad_area                  = nothing
    solar_rad_coeff                 = nothing
    drag_area                       = nothing
    drag_coeff                      = nothing
    seen                            = Set{String}()

    if !isnothing(spacecraft_parameters_nodes)
        for node in spacecraft_parameters_nodes
            lt = _omm_tag(node, strict)
            nc = children(node)
            v  = isempty(nc) ? "" : value(first(nc))

            if lt == "COMMENT"
                push!(spacecraft_parameters_comments, v)
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
            elseif lt == "DRAG_COEFF"
                drag_coeff = parse(Float64, v)
            end
        end
    end

    # == Parse TLE Related Parameters ======================================================

    tle_parameters_comments = String[]
    ephemeris_type          = nothing
    classification_type     = nothing
    norad_cat_id            = nothing
    element_set_number      = nothing
    rev_at_epoch            = nothing
    bstar                   = nothing
    bterm                   = nothing
    mean_motion_dot         = nothing
    mean_motion_ddot        = nothing
    agom                    = nothing
    seen                    = Set{String}()

    if !isnothing(tle_parameters_nodes)
        for node in tle_parameters_nodes
            lt = _omm_tag(node, strict)
            nc = children(node)
            v  = isempty(nc) ? "" : value(first(nc))

            if lt == "COMMENT"
                push!(tle_parameters_comments, v)
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
            elseif lt == "AGOM"
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
    end

    # == Covariance Matrix ================================================================

    covariance_matrix = nothing

    if !isnothing(covariance_matrix_nodes)
        cov_comments     = String[]
        cov_ref_frame    = nothing
        cx_x             = nothing
        cy_x             = nothing
        cy_y             = nothing
        cz_x             = nothing
        cz_y             = nothing
        cz_z             = nothing
        cx_dot_x         = nothing
        cx_dot_y         = nothing
        cx_dot_z         = nothing
        cx_dot_x_dot     = nothing
        cy_dot_x         = nothing
        cy_dot_y         = nothing
        cy_dot_z         = nothing
        cy_dot_x_dot     = nothing
        cy_dot_y_dot     = nothing
        cz_dot_x         = nothing
        cz_dot_y         = nothing
        cz_dot_z         = nothing
        cz_dot_x_dot     = nothing
        cz_dot_y_dot     = nothing
        cz_dot_z_dot     = nothing
        seen             = Set{String}()

        for node in covariance_matrix_nodes
            lt = _omm_tag(node, strict)
            nc = children(node)
            v  = isempty(nc) ? "" : value(first(nc))

            if lt == "COMMENT"
                push!(cov_comments, v)
                continue
            end

            lt in seen && throw(ArgumentError("Duplicate OMM covariance element `$lt`."))
            push!(seen, lt)

            if lt == "COV_REF_FRAME"
                cov_ref_frame = v
            elseif lt == "CX_X"
                cx_x = parse(Float64, v)
            elseif lt == "CY_X"
                cy_x = parse(Float64, v)
            elseif lt == "CY_Y"
                cy_y = parse(Float64, v)
            elseif lt == "CZ_X"
                cz_x = parse(Float64, v)
            elseif lt == "CZ_Y"
                cz_y = parse(Float64, v)
            elseif lt == "CZ_Z"
                cz_z = parse(Float64, v)
            elseif lt == "CX_DOT_X"
                cx_dot_x = parse(Float64, v)
            elseif lt == "CX_DOT_Y"
                cx_dot_y = parse(Float64, v)
            elseif lt == "CX_DOT_Z"
                cx_dot_z = parse(Float64, v)
            elseif lt == "CX_DOT_X_DOT"
                cx_dot_x_dot = parse(Float64, v)
            elseif lt == "CY_DOT_X"
                cy_dot_x = parse(Float64, v)
            elseif lt == "CY_DOT_Y"
                cy_dot_y = parse(Float64, v)
            elseif lt == "CY_DOT_Z"
                cy_dot_z = parse(Float64, v)
            elseif lt == "CY_DOT_X_DOT"
                cy_dot_x_dot = parse(Float64, v)
            elseif lt == "CY_DOT_Y_DOT"
                cy_dot_y_dot = parse(Float64, v)
            elseif lt == "CZ_DOT_X"
                cz_dot_x = parse(Float64, v)
            elseif lt == "CZ_DOT_Y"
                cz_dot_y = parse(Float64, v)
            elseif lt == "CZ_DOT_Z"
                cz_dot_z = parse(Float64, v)
            elseif lt == "CZ_DOT_X_DOT"
                cz_dot_x_dot = parse(Float64, v)
            elseif lt == "CZ_DOT_Y_DOT"
                cz_dot_y_dot = parse(Float64, v)
            elseif lt == "CZ_DOT_Z_DOT"
                cz_dot_z_dot = parse(Float64, v)
            else
                throw(ArgumentError("Unknown OMM covariance element `$lt`."))
            end
        end

        # Check if all 21 required matrix elements are present.
        for (name, val) in (
            ("CX_X",             cx_x),
            ("CY_X",             cy_x),
            ("CY_Y",             cy_y),
            ("CZ_X",             cz_x),
            ("CZ_Y",             cz_y),
            ("CZ_Z",             cz_z),
            ("CX_DOT_X",         cx_dot_x),
            ("CX_DOT_Y",         cx_dot_y),
            ("CX_DOT_Z",         cx_dot_z),
            ("CX_DOT_X_DOT",     cx_dot_x_dot),
            ("CY_DOT_X",         cy_dot_x),
            ("CY_DOT_Y",         cy_dot_y),
            ("CY_DOT_Z",         cy_dot_z),
            ("CY_DOT_X_DOT",     cy_dot_x_dot),
            ("CY_DOT_Y_DOT",     cy_dot_y_dot),
            ("CZ_DOT_X",         cz_dot_x),
            ("CZ_DOT_Y",         cz_dot_y),
            ("CZ_DOT_Z",         cz_dot_z),
            ("CZ_DOT_X_DOT",     cz_dot_x_dot),
            ("CZ_DOT_Y_DOT",     cz_dot_y_dot),
            ("CZ_DOT_Z_DOT",     cz_dot_z_dot),
        )
            isnothing(val) && throw(ArgumentError(
                "OMM covariance matrix is missing required element `$name`."
            ))
        end

        covariance_matrix = OmmCovarianceMatrix(
            cov_comments,
            cov_ref_frame,
            cx_x,
            cy_x,
            cy_y,
            cz_x,
            cz_y,
            cz_z,
            cx_dot_x,
            cx_dot_y,
            cx_dot_z,
            cx_dot_x_dot,
            cy_dot_x,
            cy_dot_y,
            cy_dot_z,
            cy_dot_x_dot,
            cy_dot_y_dot,
            cz_dot_x,
            cz_dot_y,
            cz_dot_z,
            cz_dot_x_dot,
            cz_dot_y_dot,
            cz_dot_z_dot
        )
    end

    # == User-Defined Parameters ===========================================================

    user_defined_parameters = nothing

    if !isnothing(user_defined_parameter_nodes)
        user_defined_parameters = Pair{String, String}[]

        for node in user_defined_parameter_nodes
            lt = _omm_tag(node, strict)
            nc = children(node)
            v  = isempty(nc) ? "" : value(first(nc))

            if lt == "USER_DEFINED"
                att = attributes(node)
                (isnothing(att) || !haskey(att, "parameter")) && throw(ArgumentError(
                    "OMM `USER_DEFINED` element is missing required attribute `parameter`."
                ))
                key = att["parameter"]
                push!(user_defined_parameters, Pair(key, v))
            else
                throw(ArgumentError("Unknown user-defined parameter element `$lt`."))
            end
        end
    end

    return OmmData(
        ;
        comments = data_comments,
        mean_elements_comments,
        epoch,
        semi_major_axis,
        mean_motion,
        eccentricity,
        inclination,
        raan,
        arg_of_pericenter,
        mean_anomaly,
        GM,
        spacecraft_parameters_comments,
        mass,
        solar_rad_area,
        solar_rad_coeff,
        drag_area,
        drag_coeff,
        tle_parameters_comments,
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
        covariance_matrix,
        user_defined_parameters,
    )
end
