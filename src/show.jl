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

    # Pre-allocate a single reusable buffer for the fields of every section, tracked by
    # the ranges below. This avoids allocating six separate vectors and the final vcat.
    buf_fields = Tuple{String, String, String}[]
    sizehint!(buf_fields, 50)

    section_ranges = UnitRange{Int}[]

    # == Header ============================================================================

    header = omm.header

    start_idx = length(buf_fields) + 1
    _po!(buf_fields, ("Comment",        header.comment,        ""))
    _po!(buf_fields, ("Classification", header.classification, ""))
    _po!(buf_fields, ("Creation Date",  header.creation_date,  ""))
    _po!(buf_fields, ("Originator",     header.originator,     ""))
    _po!(buf_fields, ("Message ID",     header.message_id,     ""))
    push!(section_ranges, start_idx:length(buf_fields))

    # == Body ==============================================================================

    # -- Metadata --------------------------------------------------------------------------

    metadata = omm.body.segment.metadata

    start_idx = length(buf_fields) + 1
    _po!(buf_fields, ("Comment",             metadata.comment,             ""))
    _po!(buf_fields, ("Object Name",         metadata.object_name,         ""))
    _po!(buf_fields, ("Object ID",           metadata.object_id,           ""))
    _po!(buf_fields, ("Center Name",         metadata.center_name,         ""))
    _po!(buf_fields, ("Ref. Frame",          metadata.ref_frame,           ""))
    _po!(buf_fields, ("Ref. Frame Epoch",    metadata.ref_frame_epoch,     ""))
    _po!(buf_fields, ("Time System",         metadata.time_system,         ""))
    _po!(buf_fields, ("Mean Element Theory", metadata.mean_element_theory, ""))
    push!(section_ranges, start_idx:length(buf_fields))

    # -- Data ------------------------------------------------------------------------------

    data = omm.body.segment.data

    # .. Mean Elements .....................................................................

    start_idx = length(buf_fields) + 1
    _po!(buf_fields, ("Comment",            data.data_comment,            ""))
    _po!(buf_fields, ("Epoch",              data.epoch,                   ""))
    _po!(buf_fields, ("Semi-Major Axis",    data.semi_major_axis,         "km"))
    _po!(buf_fields, ("Mean Motion",        data.mean_motion,             "rev/day"))
    _po!(buf_fields, ("Eccentricity",       data.eccentricity,            ""))
    _po!(buf_fields, ("Inclination",        data.inclination,             "°"))
    _po!(buf_fields, ("RA of Asc. Node",    data.raan,                    "°"))
    _po!(buf_fields, ("Arg. of Pericenter", data.arg_of_pericenter,       "°"))
    _po!(buf_fields, ("Mean Anomaly",       data.mean_anomaly,            "°"))
    _po!(buf_fields, ("GM",                 data.GM,                      "km³/s²"))
    push!(section_ranges, start_idx:length(buf_fields))

    # .. Spacecraft Parameters .............................................................

    start_idx = length(buf_fields) + 1
    _po!(buf_fields, ("Comment",           data.spacecraft_data_comment, ""))
    _po!(buf_fields, ("Mass",              data.mass,                    "kg"))
    _po!(buf_fields, ("Solar Rad. Area",   data.solar_rad_area,          "m²"))
    _po!(buf_fields, ("Solar Rad. Coeff.", data.solar_rad_coeff,         ""))
    _po!(buf_fields, ("Drag Area",         data.drag_area,               "m²"))
    _po!(buf_fields, ("Drag Coefficient",  data.drag_coeff,              ""))
    push!(section_ranges, start_idx:length(buf_fields))

    # .. TLE Related Parameters ............................................................

    start_idx = length(buf_fields) + 1
    _po!(buf_fields, ("Comment",             data.tle_parameters_comment, ""))
    _po!(buf_fields, ("Ephemeris Type",      data.ephemeris_type,         ""))
    _po!(buf_fields, ("Classification Type", data.classification_type,    ""))
    _po!(buf_fields, ("NORAD Cat ID",        data.norad_cat_id,           ""))
    _po!(buf_fields, ("Element Set Number",  data.element_set_number,     ""))
    _po!(buf_fields, ("Rev at Epoch",        data.rev_at_epoch,           ""))
    _po!(buf_fields, ("Bstar",               data.bstar,                  ""))
    _po!(buf_fields, (" ∂(Mean Motion)/∂t ", data.mean_motion_dot,        "rev/day²"))
    _po!(buf_fields, ("∂²(Mean Motion)/∂t²", data.mean_motion_ddot,       "rev/day³"))
    push!(section_ranges, start_idx:length(buf_fields))

    # .. User-Defined Parameters ...........................................................

    start_idx = length(buf_fields) + 1

    if !isnothing(data.user_defined_parameters)
        for (k, v) in data.user_defined_parameters
            _po!(buf_fields, (k, v, ""))
        end
    end

    push!(section_ranges, start_idx:length(buf_fields))

    # == Print Output ======================================================================

    out = IOContext(IOBuffer(), :color => get(io, :color, false))

    println(out, "OrbitMeanElementsMessage:")

    nfw = _field_name_width(buf_fields)
    vfw = _field_value_width(buf_fields)

    first_level_face = StyledStrings.Face(; foreground = :magenta, weight = :bold)

    # Section indices: 1=header, 2=metadata, 3=mean elements, 4=spacecraft,
    # 5=TLE, 6=user-defined.
    has_sc    = !isempty(section_ranges[4])
    has_tle   = !isempty(section_ranges[5])
    has_user  = !isempty(section_ranges[6])

    # Print Header.
    _print_level_opening(out, "Header\n", 1; name_face = first_level_face)
    _print_level_fields(
        out,
        @view(buf_fields[section_ranges[1]]),
        "",
        2,
        4,
        nfw,
        vfw;
        newline = false
    )

    # Print Body.
    _print_level_opening(out, "Body\n", 1; name_face = first_level_face)
    _print_level_opening(out, "Segment\n", 2)

    _print_level_fields(
        out,
        @view(buf_fields[section_ranges[2]]),
        "Metadata",
        3,
        4,
        nfw,
        vfw;
        newline = false
    )

    _print_level_opening(out, "Data\n", 3; has_siblings = false)

    _print_level_fields(
        out,
        @view(buf_fields[section_ranges[3]]),
        "Mean Keplerian Elements",
        4,
        4,
        nfw,
        vfw;
        newline = has_sc || has_tle || has_user
    )

    _print_level_fields(
        out,
        @view(buf_fields[section_ranges[4]]),
        "Spacecraft Parameters",
        4,
        4,
        nfw,
        vfw;
        newline = has_tle || has_user
    )

    _print_level_fields(
        out,
        @view(buf_fields[section_ranges[5]]),
        "TLE Related Parameters",
        4,
        4,
        nfw,
        vfw;
        newline = has_user
    )

    _print_level_fields(
        out,
        @view(buf_fields[section_ranges[6]]),
        "User-Defined Parameters",
        4,
        4,
        nfw,
        vfw;
        newline = false
    )

    _print_level_opening(out, "", 4; has_siblings = false)

    print(io, String(take!(out.io)))

    return nothing
end

