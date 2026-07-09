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

    header = omm.header

    header_fields = NTuple{3, String}[]
    _po!(header_fields, ("Comment",        header.comment,        ""))
    _po!(header_fields, ("Classification", header.classification, ""))
    _po!(header_fields, ("Creation Date",  header.creation_date,  ""))
    _po!(header_fields, ("Originator",     header.originator,     ""))
    _po!(header_fields, ("Message ID",     header.message_id,     ""))

    # == Metadata ==========================================================================

    metadata = omm.body.segment.metadata

    metadata_fields = NTuple{3, String}[]
    _po!(metadata_fields, ("Comment",             metadata.comment,             ""))
    _po!(metadata_fields, ("Object Name",         metadata.object_name,         ""))
    _po!(metadata_fields, ("Object ID",           metadata.object_id,           ""))
    _po!(metadata_fields, ("Center Name",         metadata.center_name,         ""))
    _po!(metadata_fields, ("Ref. Frame",          metadata.ref_frame,           ""))
    _po!(metadata_fields, ("Ref. Frame Epoch",    metadata.ref_frame_epoch,     ""))
    _po!(metadata_fields, ("Time System",         metadata.time_system,         ""))
    _po!(metadata_fields, ("Mean Element Theory", metadata.mean_element_theory, ""))

    # == Data ==============================================================================

    data = omm.body.segment.data

    # -- Mean Keplerian Elements -----------------------------------------------------------

    mean_elements_fields = NTuple{3, String}[]
    _po!(mean_elements_fields, ("Comment",            data.data_comment,      ""))
    _po!(mean_elements_fields, ("Epoch",              data.epoch,             ""))
    _po!(mean_elements_fields, ("Semi-Major Axis",    data.semi_major_axis,   "km"))
    _po!(mean_elements_fields, ("Mean Motion",        data.mean_motion,       "rev/day"))
    _po!(mean_elements_fields, ("Eccentricity",       data.eccentricity,      ""))
    _po!(mean_elements_fields, ("Inclination",        data.inclination,       "°"))
    _po!(mean_elements_fields, ("RA of Asc. Node",    data.raan,              "°"))
    _po!(mean_elements_fields, ("Arg. of Pericenter", data.arg_of_pericenter, "°"))
    _po!(mean_elements_fields, ("Mean Anomaly",       data.mean_anomaly,      "°"))
    _po!(mean_elements_fields, ("GM",                 data.GM,                "km³/s²"))

    # -- Spacecraft Parameters -------------------------------------------------------------

    spacecraft_fields = NTuple{3, String}[]
    _po!(spacecraft_fields, ("Comment",           data.spacecraft_data_comment, ""))
    _po!(spacecraft_fields, ("Mass",              data.mass,                    "kg"))
    _po!(spacecraft_fields, ("Solar Rad. Area",   data.solar_rad_area,          "m²"))
    _po!(spacecraft_fields, ("Solar Rad. Coeff.", data.solar_rad_coeff,         ""))
    _po!(spacecraft_fields, ("Drag Area",         data.drag_area,               "m²"))
    _po!(spacecraft_fields, ("Drag Coefficient",  data.drag_coeff,              ""))

    # -- TLE Related Parameters ------------------------------------------------------------

    tle_fields = NTuple{3, String}[]
    _po!(tle_fields, ("Comment",             data.tle_parameters_comment, ""))
    _po!(tle_fields, ("Ephemeris Type",      data.ephemeris_type,         ""))
    _po!(tle_fields, ("Classification Type", data.classification_type,    ""))
    _po!(tle_fields, ("NORAD Cat ID",        data.norad_cat_id,           ""))
    _po!(tle_fields, ("Element Set Number",  data.element_set_number,     ""))
    _po!(tle_fields, ("Rev at Epoch",        data.rev_at_epoch,           ""))
    _po!(tle_fields, ("Bstar",               data.bstar,                  ""))
    _po!(tle_fields, ("∂(Mean Motion)/∂t",  data.mean_motion_dot,        "rev/day²"))
    _po!(tle_fields, ("∂²(Mean Motion)/∂t²", data.mean_motion_ddot,       "rev/day³"))

    # -- Covariance Matrix -----------------------------------------------------------------

    cov_fields = NTuple{3, String}[]
    if !isnothing(data.covariance_matrix)
        cov = data.covariance_matrix
        _po!(cov_fields, ("Comment",       cov.comment,       ""))
        _po!(cov_fields, ("Ref. Frame",    cov.cov_ref_frame, ""))
        _po!(cov_fields, ("CX_X",          cov.cx_x,          "km²"))
        _po!(cov_fields, ("CY_X",          cov.cy_x,          "km²"))
        _po!(cov_fields, ("CY_Y",          cov.cy_y,          "km²"))
        _po!(cov_fields, ("CZ_X",          cov.cz_x,          "km²"))
        _po!(cov_fields, ("CZ_Y",          cov.cz_y,          "km²"))
        _po!(cov_fields, ("CZ_Z",          cov.cz_z,          "km²"))
        _po!(cov_fields, ("CX_DOT_X",      cov.cx_dot_x,      "km²/s"))
        _po!(cov_fields, ("CX_DOT_Y",      cov.cx_dot_y,      "km²/s"))
        _po!(cov_fields, ("CX_DOT_Z",      cov.cx_dot_z,      "km²/s"))
        _po!(cov_fields, ("CX_DOT_X_DOT",  cov.cx_dot_x_dot,  "km²/s²"))
        _po!(cov_fields, ("CY_DOT_X",      cov.cy_dot_x,      "km²/s"))
        _po!(cov_fields, ("CY_DOT_Y",      cov.cy_dot_y,      "km²/s"))
        _po!(cov_fields, ("CY_DOT_Z",      cov.cy_dot_z,      "km²/s"))
        _po!(cov_fields, ("CY_DOT_X_DOT",  cov.cy_dot_x_dot,  "km²/s²"))
        _po!(cov_fields, ("CY_DOT_Y_DOT",  cov.cy_dot_y_dot,  "km²/s²"))
        _po!(cov_fields, ("CZ_DOT_X",      cov.cz_dot_x,      "km²/s"))
        _po!(cov_fields, ("CZ_DOT_Y",      cov.cz_dot_y,      "km²/s"))
        _po!(cov_fields, ("CZ_DOT_Z",      cov.cz_dot_z,      "km²/s"))
        _po!(cov_fields, ("CZ_DOT_X_DOT",  cov.cz_dot_x_dot,  "km²/s²"))
        _po!(cov_fields, ("CZ_DOT_Y_DOT",  cov.cz_dot_y_dot,  "km²/s²"))
        _po!(cov_fields, ("CZ_DOT_Z_DOT",  cov.cz_dot_z_dot,  "km²/s²"))
    end

    # -- User-Defined Parameters -----------------------------------------------------------

    user_fields = NTuple{3, String}[]
    if !isnothing(data.user_defined_parameters)
        for (k, v) in data.user_defined_parameters
            _po!(user_fields, (k, v, ""))
        end
    end

    # == Print Output ======================================================================

    out = IOContext(IOBuffer(), :color => get(io, :color, false))

    # Rails used to draw the tree. `Segment` is the only child of `Body`, hence the space
    # below it; `Metadata`/`Data` and the data subsections carry a `│` rail while they still
    # have siblings.
    metadata_rail = "     │    "
    data_rail     = "        "

    _print_node(out, "OrbitMeanElementsMessage:", "", "", :satellitetoolbox_odm_title)

    # -- Header (top-level heading, drawn without a connector) ------------------------------

    _print_node(out, "Header", "  ", "", :satellitetoolbox_odm_section)
    _print_fields(out, header_fields, "    ")

    # -- Body ------------------------------------------------------------------------------

    _print_node(out, "Body", "  ", "", :satellitetoolbox_odm_section)
    _print_node(out, "Segment", "  ", "└─ ", :satellitetoolbox_odm_node)

    # .. Metadata ..........................................................................

    _print_node(out, "Metadata", "     ", "├─ ", :satellitetoolbox_odm_node)
    _print_fields(out, metadata_fields, metadata_rail)

    # .. Data ..............................................................................

    _print_node(out, "Data", "     ", "└─ ", :satellitetoolbox_odm_node)

    # Build the list of present data subsections so the last one is closed with `└─`.
    data_sections = filter(
        s -> !isempty(s[2]),
        [
            ("Mean Keplerian Elements", mean_elements_fields),
            ("Spacecraft Parameters",   spacecraft_fields),
            ("TLE Related Parameters",  tle_fields),
            ("Covariance Matrix",       cov_fields),
            ("User-Defined Parameters", user_fields),
        ]
    )

    for (i, (title, fields)) in enumerate(data_sections)
        is_last   = i == length(data_sections)
        connector = is_last ? "└─ " : "├─ "
        field_rail = data_rail * (is_last ? "     " : "│    ")

        _print_node(out, title, data_rail, connector, :satellitetoolbox_odm_node)
        _print_fields(out, fields, field_rail)
    end

    print(io, String(take!(out.io)))

    return nothing
end

