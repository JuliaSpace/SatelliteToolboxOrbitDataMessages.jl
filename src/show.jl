## Description #############################################################################
#
# Show methods.
#
############################################################################################

# == OrbitMeanElementsMessage ==============================================================

function Base.show(io::IO, omm::OrbitMeanElementsMessage)
    obj_name = omm.body.segment.metadata.object_name
    obj_id   = omm.body.segment.metadata.object_id
    epoch    = omm.body.segment.data.epoch
    output   = "OMM: $obj_name [$obj_id] (Epoch = $epoch)"

    print(io, output)
    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", omm::OrbitMeanElementsMessage)
    _po! = _push_output!

    # == Header ============================================================================

    header_out = Tuple{String, String, String}[]
    header     = omm.header

    _po!(header_out, ("Comment",        header.comment,        ""))
    _po!(header_out, ("Classification", header.classification, ""))
    _po!(header_out, ("Creation Date",  header.creation_date,  ""))
    _po!(header_out, ("Originator",     header.originator,     ""))
    _po!(header_out, ("Message ID",     header.message_id,     ""))

    # == Body ==============================================================================

    # -- Metadata --------------------------------------------------------------------------

    body_metadata_out = Tuple{String, String, String}[]
    metadata          = omm.body.segment.metadata

    _po!(body_metadata_out, ("Comment",             metadata.comment,             ""))
    _po!(body_metadata_out, ("Object Name",         metadata.object_name,         ""))
    _po!(body_metadata_out, ("Object ID",           metadata.object_id,           ""))
    _po!(body_metadata_out, ("Center Name",         metadata.center_name,         ""))
    _po!(body_metadata_out, ("Ref. Frame",          metadata.ref_frame,           ""))
    _po!(body_metadata_out, ("Ref. Frame Epoch",    metadata.ref_frame_epoch,     ""))
    _po!(body_metadata_out, ("Time System",         metadata.time_system,         ""))
    _po!(body_metadata_out, ("Mean Element Theory", metadata.mean_element_theory, ""))

    # -- Data ------------------------------------------------------------------------------

    data = omm.body.segment.data

    # .. Mean Elements .....................................................................

    body_kep_out = Tuple{String, String, String}[]

    _po!(body_kep_out, ("Comment",            data.data_comment,            ""))
    _po!(body_kep_out, ("Epoch",              data.epoch,                   ""))
    _po!(body_kep_out, ("Semi-Major Axis",    data.semi_major_axis,         "km"))
    _po!(body_kep_out, ("Mean Motion",        data.mean_motion,             "rev/day"))
    _po!(body_kep_out, ("Eccentricity",       data.eccentricity,            ""))
    _po!(body_kep_out, ("Inclination",        data.inclination,             "°"))
    _po!(body_kep_out, ("RA of Asc. Node",    data.raan,                    "°"))
    _po!(body_kep_out, ("Arg. of Pericenter", data.arg_of_pericenter,       "°"))
    _po!(body_kep_out, ("Mean Anomaly",       data.mean_anomaly,            "°"))
    _po!(body_kep_out, ("GM",                 data.GM,                      "km³/s²"))

    # .. Spacecraft Parameters .............................................................

    body_sc_data_out = Tuple{String, String, String}[]

    _po!(body_sc_data_out, ("Comment",           data.spacecraft_data_comment, ""))
    _po!(body_sc_data_out, ("Mass",              data.mass,                    "kg"))
    _po!(body_sc_data_out, ("Solar Rad. Area",   data.solar_rad_area,          "m²"))
    _po!(body_sc_data_out, ("Solar Rad. Coeff.", data.solar_rad_coeff,         ""))
    _po!(body_sc_data_out, ("Drag Area",         data.drag_area,               "m²"))
    _po!(body_sc_data_out, ("Drag Coefficient",  data.drag_coeff,              ""))

    # .. TLE Related Parameters ............................................................

    body_tle_out = Tuple{String, String, String}[]

    _po!(body_tle_out, ("Comment",             data.tle_parameters_comment, ""))
    _po!(body_tle_out, ("Ephemeris Type",      data.ephemeris_type,         ""))
    _po!(body_tle_out, ("Classification Type", data.classification_type,    ""))
    _po!(body_tle_out, ("NORAD Cat ID",        data.norad_cat_id,           ""))
    _po!(body_tle_out, ("Element Set Number",  data.element_set_number,     ""))
    _po!(body_tle_out, ("Rev at Epoch",        data.rev_at_epoch,           ""))
    _po!(body_tle_out, ("Bstar",               data.bstar,                  ""))
    _po!(body_tle_out, (" ∂(Mean Motion)/∂t ", data.mean_motion_dot,        "rev/day²"))
    _po!(body_tle_out, ("∂²(Mean Motion)/∂t²", data.mean_motion_ddot,       "rev/day³"))

    # .. User-Defined Parameters ...........................................................

    body_user_defined_out = Tuple{String, String, String}[]

    if !isnothing(data.user_defined_parameters)
        for (k, v) in data.user_defined_parameters
            _po!(body_user_defined_out, (k, v, ""))
        end
    end

    # == Print Output ======================================================================

    buf = IOContext(IOBuffer(), :color => get(io, :color, false))

    println(buf, "OrbitMeanElementsMessage:")

    v = vcat(header_out, body_metadata_out, body_kep_out, body_sc_data_out, body_tle_out)

    nfw = _field_name_width(v)
    vfw = _field_value_width(v)

    first_level_face = StyledStrings.Face(; foreground = :magenta, weight = :bold)

    # Print Header.
    _print_level_opening(buf, "Header\n", 1; name_face = first_level_face)
    _print_level_fields(buf, header_out, "", 2, 4, nfw, vfw; newline = false)

    # Print Body.
    _print_level_opening(buf, "Body\n", 1; name_face = first_level_face)
    _print_level_opening(buf, "Segment\n", 2)

    _print_level_fields(buf, body_metadata_out, "Metadata", 3, 4, nfw, vfw, newline = false)

    _print_level_opening(buf, "Data\n", 3; has_siblings = false)

    nl = !isempty(body_sc_data_out) || !isempty(body_tle_out) || !isempty(body_user_defined_out)
    _print_level_fields(
        buf,
        body_kep_out,
        "Mean Keplerian Elements",
        4,
        4,
        nfw,
        vfw;
        newline = nl
    )

    nl = !isempty(body_tle_out) || !isempty(body_user_defined_out)
    _print_level_fields(
        buf,
        body_sc_data_out,
        "Spacecraft Parameters",
        4,
        4,
        nfw,
        vfw;
        newline = nl
    )

    nl = !isempty(body_user_defined_out)
    _print_level_fields(
        buf,
        body_tle_out,
        "TLE Related Parameters",
        4,
        4,
        nfw,
        vfw;
        newline = nl
    )

    _print_level_fields(
        buf,
        body_user_defined_out,
        "User-Defined Parameters",
        4,
        4,
        nfw,
        vfw;
        newline = false
    )

    _print_level_opening(buf, "", 4; has_siblings = false)

    print(io, String(take!(buf.io)))

    return nothing
end

