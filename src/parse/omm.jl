## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM).
#
############################################################################################

export parse_omm, parse_omms

"""
    parse_omm(str::String) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) in the string `str` and return the parsed
message. The input format must be XML.

    parse_omm(xml::LazyNode) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml` and return the parsed
message.

If the XML is a Navigation Data Message (NDM), only the first OMM message is returned. If
the file does not contain an OMM message, `nothing` is returned.
"""
function parse_omm(str::String)
    # Open the XML file.
    xml = parse(str, LazyNode)
    return parse_omm(xml)
end

function parse_omm(xml::LazyNode)
    for node in xml
        tag(node) == "omm" && return _parse_omm(node)
    end

    return nothing
end

"""
    parse_omms(str::String) -> Union{Nothing, Vector{OrbitMeanElementsMessage}}

Parse a set of Orbit Mean-Elements Messages (OMM) string `str` and return the parsed
messages. The input format must be XML.

    parse_omms(xml::LazyNode) -> Union{Nothing, Vector{OrbitMeanElementsMessage}}

Parse a set of Orbit Mean-Elements Messages (OMM) from a `LazyNode` `xml` and return the
parsed messages.

If the XML is a Navigation Data Message (NDM), only the OMM messages are returned. If the
file does not contain an OMM message, `nothing` is returned.
"""
function parse_omms(str::String)
    # Open the XML file.
    xml = parse(str, LazyNode)
    return parse_omms(xml)
end

function parse_omms(xml::LazyNode)
    omms = OrbitMeanElementsMessage[]
    root = children(xml)[end]
    t    = lowercase(tag(root))

    if t == "ndm"
        for node in children(root)
            tag(node) == "omm" && push!(omms, _parse_omm(node))
        end

        return omms

    elseif t == "omm"
        push!(omms, _parse_omm(root))
        return omms
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _parse_omm(xml::LazyNode) -> OrbitMeanElementsMessage

Parse an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml` representation.
"""
function _parse_omm(xml::LazyNode)
    lowercase(tag(xml)) != "omm" && throw(
        ArgumentError("The provided XML does not contain an OMM element.")
    )

    # Extract the version attribute.
    att = attributes(xml)

    (!haskey(att, "id") || lowercase(att["id"]) != "ccsds_omm_vers") && throw(ArgumentError(
        "The OMM element is missing the required `id = CCSDS_OMM_VERSION` attribute."
    ))

    !haskey(att, "version") && throw(ArgumentError(
        "The OMM element is missing the required `version` attribute."
    ))

    version = VersionNumber(att["version"])

    # The difference between versions 2 and 3 are negligible for our purposes.
    !(v"2.0.0" <= version <= v"3.0.0") &&
        throw(ArgumentError("Unsupported OMM version: $version."))

    nodes = children(xml)

    # == Parse Header ======================================================================

    header_id = findfirst(n -> lowercase(tag(n)) == "header", nodes)

    isnothing(header_id) && throw(ArgumentError("The OMM element is missing the header."))

    header = _parse_omm_header(nodes[header_id])

    # == Parse Body ========================================================================

    body_id = findfirst(n -> lowercase(tag(n)) == "body", nodes)

    isnothing(body_id) && throw(ArgumentError("The OMM element is missing the body."))

    body = _parse_omm_body(nodes[body_id])

    return OrbitMeanElementsMessage(version, header, body)
end

# == Header Parsing ========================================================================

"""
    _parse_omm_header(xml::LazyNode) -> OmmHeader

Parse the header of an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml`
representation.
"""
function _parse_omm_header(xml::LazyNode)
    comment        = nothing
    classification = nothing
    creation_date  = nothing
    originator     = nothing
    message_id     = nothing

    for node in children(xml)
        t  = tag(node)
        ch = children(node)
        v  = isempty(ch) ? "" : value(first(ch))

        if lowercase(t) == "comment"
            comment = v
        elseif lowercase(t) == "classification"
            classification = v
        elseif lowercase(t) == "creation_date"
            creation_date = !isempty(v) ? NanoDate(v) : NanoDate()
        elseif lowercase(t) == "originator"
            originator = v
        elseif lowercase(t) == "message_id"
            message_id = v
        end
    end

    # Check if all required fields are present.
    if isnothing(creation_date)
        error("OMM header is missing required field `CREATION_DATE`.")
    end

    if isnothing(originator)
        error("OMM header is missing required field `ORIGINATOR`.")
    end

    return OmmHeader(
        comment,
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
function _parse_omm_body(xml::LazyNode)
    ch = children(xml)
    segment_ids = findall(n -> lowercase(tag(n)) == "segment", ch)

    isempty(segment_ids) && throw(ArgumentError("The OMM body is missing the segment."))
    length(segment_ids) > 1 && throw(ArgumentError(
        "The OMM body contains multiple segments, which is not supported."
    ))

    segment = _parse_omm_segment(ch[first(segment_ids)])

    return OmmBody(segment)
end

# -- Body Segment Parsing ------------------------------------------------------------------

"""
    _parse_omm_segment(xml::LazyNode) -> OmmSegment

Parse a segment of the body of an Orbit Mean-Elements Message (OMM) from a `LazyNode` `xml`
representation.
"""
function _parse_omm_segment(xml::LazyNode)
    ch = children(xml)

    # Find the metadata node.
    metadata_id = findfirst(n -> lowercase(tag(n)) == "metadata", ch)
    isnothing(metadata_id) && throw(ArgumentError(
        "The OMM segment is missing the metadata section."
    ))
    metadata_nodes = ch[metadata_id]

    # Find the data node.
    data_id = findfirst(n -> lowercase(tag(n)) == "data", ch)
    isnothing(data_id) && throw(ArgumentError(
        "The OMM segment is missing the data section."
    ))
    data_nodes = ch[data_id]

    # == Parse Metadata ====================================================================

    metadata = _parse_omm_metadata(metadata_nodes)

    # == Parse Data ========================================================================

    data = _parse_omm_data(data_nodes)

    return OmmSegment(metadata, data)
end

"""
    _parse_omm_metadata(xml::LazyNode) -> OmmMetadata

Parse the metadata of the segment body of an Orbit Mean-Elements Message (OMM) from a
`LazyNode` `xml` representation.
"""
function _parse_omm_metadata(xml::LazyNode)
    ch = children(xml)

    comment             = nothing
    object_name         = nothing
    object_id           = nothing
    center_name         = nothing
    ref_frame           = nothing
    ref_frame_epoch     = nothing
    time_system         = nothing
    mean_element_theory = nothing

    for node in ch
        t  = tag(node)
        ch = children(node)
        v  = isempty(ch) ? "" : value(first(ch))

        if lowercase(t) == "comment"
            comment = v
        elseif lowercase(t) == "object_name"
            object_name = v
        elseif lowercase(t) == "object_id"
            object_id = v
        elseif lowercase(t) == "center_name"
            center_name = v
        elseif lowercase(t) == "ref_frame"
            ref_frame = v
        elseif lowercase(t) == "ref_frame_epoch"
            ref_frame_epoch = !isempty(v) ? NanoDate(v) : NanoDate()
        elseif lowercase(t) == "time_system"
            time_system = v
        elseif lowercase(t) == "mean_element_theory"
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
        comment,
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
function _parse_omm_data(xml::LazyNode)
    ch = children(xml)

    data_comment                 = nothing
    mean_elements_nodes          = nothing
    spacecraft_parameters_nodes  = nothing
    tle_parameters_nodes         = nothing
    user_defined_parameter_nodes = nothing

    for node in ch
        t  = tag(node)
        ch = children(node)

        if lowercase(t) == "comment"
            v  = isempty(ch) ? "" : value(first(ch))
            data_comment = v
        elseif lowercase(t) == "meanelements"
            mean_elements_nodes = ch
        elseif lowercase(t) == "spacecraftparameters"
            spacecraft_parameters_nodes = ch
        elseif lowercase(t) == "tleparameters"
            tle_parameters_nodes = ch
        elseif lowercase(t) == "userdefinedparameters"
            user_defined_parameter_nodes = ch
        end
    end

    # == Parse Mean Elements ===============================================================

    isnothing(mean_elements_nodes) && throw(ArgumentError(
        "The OMM data is missing the required section `meanElements`."
    ))

    epoch             = nothing
    semi_major_axis   = nothing
    mean_motion       = nothing
    eccentricity      = nothing
    inclination       = nothing
    raan              = nothing
    arg_of_pericenter = nothing
    mean_anomaly      = nothing
    GM                = nothing

    for node in mean_elements_nodes
        t  = tag(node)
        ch = children(node)
        v  = isempty(ch) ? "" : value(first(ch))

        if lowercase(t) == "epoch"
            epoch = !isempty(v) ? NanoDate(v) : NanoDate()
        elseif lowercase(t) == "semi_major_axis"
            semi_major_axis = parse(Float64, v)
        elseif lowercase(t) == "mean_motion"
            mean_motion = parse(Float64, v)
        elseif lowercase(t) == "eccentricity"
            eccentricity = parse(Float64, v)
        elseif lowercase(t) == "inclination"
            inclination = parse(Float64, v)
        elseif lowercase(t) == "ra_of_asc_node"
            raan = parse(Float64, v)
        elseif lowercase(t) == "arg_of_pericenter"
            arg_of_pericenter = parse(Float64, v)
        elseif lowercase(t) == "mean_anomaly"
            mean_anomaly = parse(Float64, v)
        elseif lowercase(t) == "gm"
            GM = parse(Float64, v)
        end
    end

    # Check if all required fields are present.
    isnothing(epoch) && throw(ArgumentError(
        "OMM data is missing required field `EPOCH`."
    ))

    isnothing(semi_major_axis) && isnothing(mean_motion) && throw(ArgumentError(
        "OMM data is missing required field `SEMI_MAJOR_AXIS` or `MEAN_MOTION`."
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

    spacecraft_data_comment = nothing
    mass                    = nothing
    solar_rad_area          = nothing
    solar_rad_coeff         = nothing
    drag_area               = nothing
    drag_coeff              = nothing

    if !isnothing(spacecraft_parameters_nodes)
        for node in spacecraft_parameters_nodes
            t  = tag(node)
            ch = children(node)
            v  = isempty(ch) ? "" : value(first(ch))

            if lowercase(t) == "comment"
                if isnothing(spacecraft_data_comment)
                    spacecraft_data_comment = v
                end
            elseif lowercase(t) == "mass"
                mass = parse(Float64, v)
            elseif lowercase(t) == "solar_rad_area"
                solar_rad_area = parse(Float64, v)
            elseif lowercase(t) == "solar_rad_coeff"
                solar_rad_coeff = parse(Float64, v)
            elseif lowercase(t) == "drag_area"
                drag_area = parse(Float64, v)
            elseif lowercase(t) == "drag_coeff"
                drag_coeff = parse(Float64, v)
            end
        end
    end

    # == Parse TLE Related Parameters ======================================================

    tle_parameters_comment  = nothing
    ephemeris_type          = nothing
    classification_type     = nothing
    norad_cat_id            = nothing
    element_set_number      = nothing
    rev_at_epoch            = nothing
    bstar                   = nothing
    mean_motion_dot         = nothing
    mean_motion_ddot        = nothing

    if !isnothing(tle_parameters_nodes)
        for node in tle_parameters_nodes
            t  = tag(node)
            ch = children(node)
            v  = isempty(ch) ? "" : value(first(ch))

            if lowercase(t) == "comment"
                tle_parameters_comment = v
            elseif lowercase(t) == "ephemeris_type"
                ephemeris_type = parse(Int, v)
            elseif lowercase(t) == "classification_type"
                classification_type = v[1]
            elseif lowercase(t) == "norad_cat_id"
                norad_cat_id = parse(Int, v)
            elseif lowercase(t) == "element_set_no"
                element_set_number = parse(Int, v)
            elseif lowercase(t) == "rev_at_epoch"
                rev_at_epoch = parse(Int, v)
            elseif lowercase(t) == "bstar"
                bstar = parse(Float64, v)
            elseif lowercase(t) == "mean_motion_dot"
                mean_motion_dot = parse(Float64, v)
            elseif lowercase(t) == "mean_motion_ddot"
                mean_motion_ddot = parse(Float64, v)
            end
        end
    end

    # == User-Defined Parameters ===========================================================

    user_defined_parameters = nothing

    if !isnothing(user_defined_parameter_nodes)
        user_defined_parameters = Pair{String, String}[]

        for node in user_defined_parameter_nodes
            t  = tag(node)
            ch = children(node)
            v  = isempty(ch) ? "" : value(first(ch))

            if lowercase(t) == "user_defined"
                att = attributes(node)
                key = get(att, "parameter", "User Defined Paremeter")
                push!(user_defined_parameters, Pair(key, v))
            end
        end
    end

    return OmmData(
        data_comment,
        epoch,
        semi_major_axis,
        mean_motion,
        eccentricity,
        inclination,
        raan,
        arg_of_pericenter,
        mean_anomaly,
        GM,
        spacecraft_data_comment,
        mass,
        solar_rad_area,
        solar_rad_coeff,
        drag_area,
        drag_coeff,
        tle_parameters_comment,
        ephemeris_type,
        classification_type,
        norad_cat_id,
        element_set_number,
        rev_at_epoch,
        bstar,
        mean_motion_dot,
        mean_motion_ddot,
        user_defined_parameters
    )
end
