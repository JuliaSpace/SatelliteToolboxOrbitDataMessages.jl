## Description #############################################################################
#
# Show methods.
#
# The rich representation is a tree drawn with the helpers of SatelliteToolboxBase.jl: the
# header, the metadata, and the data are sections, and the data subsections are nested
# under the data.
#
############################################################################################

# == OrbitMeanElementsMessage ==============================================================

function Base.show(io::IO, omm::OrbitMeanElementsMessage)
    metadata = omm.metadata
    print(
        io,
        "OMM: ",
        metadata.object_name,
        " [",
        metadata.object_id,
        "] (Epoch = ",
        omm.data.epoch,
        ")",
    )
    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", omm::OrbitMeanElementsMessage)
    print_tree(io, "OrbitMeanElementsMessage", omm)
    return nothing
end

# The body of the rich representation is overloaded so that other types can print it under
# their own header.
function print_tree_body(io::IO, omm::OrbitMeanElementsMessage)
    _po! = _push_output!

    # == Header ============================================================================

    header = omm.header

    header_fields = PrintedField[]
    for comment in header.comments
        _po!(header_fields, "Comment", comment, "")
    end
    _po!(header_fields, "Classification", header.classification, "")
    _po!(header_fields, "Creation Date", header.creation_date, "")
    _po!(header_fields, "Originator", header.originator, "")
    _po!(header_fields, "Message ID", header.message_id, "")

    # == Metadata ==========================================================================

    metadata = omm.metadata

    metadata_fields = PrintedField[]
    for comment in metadata.comments
        _po!(metadata_fields, "Comment", comment, "")
    end
    _po!(metadata_fields, "Object Name", metadata.object_name, "")
    _po!(metadata_fields, "Object ID", metadata.object_id, "")
    _po!(metadata_fields, "Center Name", metadata.center_name, "")
    _po!(metadata_fields, "Ref. Frame", metadata.ref_frame, "")
    _po!(metadata_fields, "Ref. Frame Epoch", metadata.ref_frame_epoch, "")
    _po!(metadata_fields, "Time System", metadata.time_system, "")
    _po!(metadata_fields, "Mean Element Theory", metadata.mean_element_theory, "")

    # == Data ==============================================================================

    data = omm.data

    data_fields = PrintedField[]
    for comment in data.comments
        _po!(data_fields, "Comment", comment, "")
    end

    # -- Mean Keplerian Elements -----------------------------------------------------------

    mean_elements_fields = PrintedField[]
    for comment in data.mean_elements_comments
        _po!(mean_elements_fields, "Comment", comment, "")
    end
    _po!(mean_elements_fields, "Epoch", data.epoch, "")
    _po!(mean_elements_fields, "Semi-Major Axis", data.semi_major_axis, "km")
    _po!(mean_elements_fields, "Mean Motion", data.mean_motion, "rev/day")
    _po!(mean_elements_fields, "Eccentricity", data.eccentricity, "")
    _po!(mean_elements_fields, "Inclination", data.inclination, "°")
    _po!(mean_elements_fields, "RA of Asc. Node", data.raan, "°")
    _po!(mean_elements_fields, "Arg. of Pericenter", data.arg_of_pericenter, "°")
    _po!(mean_elements_fields, "Mean Anomaly", data.mean_anomaly, "°")
    _po!(mean_elements_fields, "GM", data.GM, "km³/s²")

    # -- Spacecraft Parameters -------------------------------------------------------------

    spacecraft_fields = PrintedField[]
    for comment in data.spacecraft_parameters_comments
        _po!(spacecraft_fields, "Comment", comment, "")
    end
    _po!(spacecraft_fields, "Mass", data.mass, "kg")
    _po!(spacecraft_fields, "Solar Rad. Area", data.solar_rad_area, "m²")
    _po!(spacecraft_fields, "Solar Rad. Coeff.", data.solar_rad_coeff, "")
    _po!(spacecraft_fields, "Drag Area", data.drag_area, "m²")
    _po!(spacecraft_fields, "Drag Coefficient", data.drag_coeff, "")

    # -- TLE Related Parameters ------------------------------------------------------------

    tle_fields = PrintedField[]
    for comment in data.tle_parameters_comments
        _po!(tle_fields, "Comment", comment, "")
    end
    _po!(tle_fields, "Ephemeris Type", data.ephemeris_type, "")
    _po!(tle_fields, "Classification Type", data.classification_type, "")
    _po!(tle_fields, "NORAD Cat ID", data.norad_cat_id, "")
    _po!(tle_fields, "Element Set Number", data.element_set_number, "")
    _po!(tle_fields, "Rev at Epoch", data.rev_at_epoch, "")
    _po!(tle_fields, "B*", data.bstar, "1/ER")
    _po!(tle_fields, "Bterm", data.bterm, "m²/kg")
    _po!(tle_fields, "∂(Mean Motion)/∂t", data.mean_motion_dot, "rev/day²")
    _po!(tle_fields, "∂²(Mean Motion)/∂t²", data.mean_motion_ddot, "rev/day³")
    _po!(tle_fields, "AGOM", data.agom, "m²/kg")

    # -- Covariance Matrix -----------------------------------------------------------------

    # Binding the `Union` field to a local lets the `isnothing` check narrow its type.
    cov_fields = PrintedField[]
    cov        = data.covariance_matrix
    if !isnothing(cov)
        for comment in cov.comments
            _po!(cov_fields, "Comment", comment, "")
        end
        _po!(cov_fields, "Ref. Frame", cov.cov_ref_frame, "")
        _po!(cov_fields, "CX_X", cov.cx_x, "km²")
        _po!(cov_fields, "CY_X", cov.cy_x, "km²")
        _po!(cov_fields, "CY_Y", cov.cy_y, "km²")
        _po!(cov_fields, "CZ_X", cov.cz_x, "km²")
        _po!(cov_fields, "CZ_Y", cov.cz_y, "km²")
        _po!(cov_fields, "CZ_Z", cov.cz_z, "km²")
        _po!(cov_fields, "CX_DOT_X", cov.cx_dot_x, "km²/s")
        _po!(cov_fields, "CX_DOT_Y", cov.cx_dot_y, "km²/s")
        _po!(cov_fields, "CX_DOT_Z", cov.cx_dot_z, "km²/s")
        _po!(cov_fields, "CX_DOT_X_DOT", cov.cx_dot_x_dot, "km²/s²")
        _po!(cov_fields, "CY_DOT_X", cov.cy_dot_x, "km²/s")
        _po!(cov_fields, "CY_DOT_Y", cov.cy_dot_y, "km²/s")
        _po!(cov_fields, "CY_DOT_Z", cov.cy_dot_z, "km²/s")
        _po!(cov_fields, "CY_DOT_X_DOT", cov.cy_dot_x_dot, "km²/s²")
        _po!(cov_fields, "CY_DOT_Y_DOT", cov.cy_dot_y_dot, "km²/s²")
        _po!(cov_fields, "CZ_DOT_X", cov.cz_dot_x, "km²/s")
        _po!(cov_fields, "CZ_DOT_Y", cov.cz_dot_y, "km²/s")
        _po!(cov_fields, "CZ_DOT_Z", cov.cz_dot_z, "km²/s")
        _po!(cov_fields, "CZ_DOT_X_DOT", cov.cz_dot_x_dot, "km²/s²")
        _po!(cov_fields, "CZ_DOT_Y_DOT", cov.cz_dot_y_dot, "km²/s²")
        _po!(cov_fields, "CZ_DOT_Z_DOT", cov.cz_dot_z_dot, "km²/s²")
    end

    # -- User-Defined Parameters -----------------------------------------------------------

    user_fields             = PrintedField[]
    user_defined_parameters = data.user_defined_parameters
    if !isnothing(user_defined_parameters)
        for (k, v) in user_defined_parameters
            _po!(user_fields, k, v, "")
        end
    end

    # == Print Output ======================================================================

    # Only the data subsections with at least one field are printed.
    data_sections = PrintedSection[]

    for (name, fields) in (
        ("Mean Keplerian Elements", mean_elements_fields),
        ("Spacecraft Parameters",   spacecraft_fields),
        ("TLE Related Parameters",  tle_fields),
        ("Covariance Matrix",       cov_fields),
        ("User-Defined Parameters", user_fields),
    )
        isempty(fields) && continue
        push!(data_sections, PrintedSection(name, fields))
    end

    sections = PrintedSection[
        PrintedSection("Header",   header_fields),
        PrintedSection("Metadata", metadata_fields),
        PrintedSection("Data",     data_fields, data_sections),
    ]

    print_tree_body(io, PrintedField[], sections)

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _format_value(value) -> String

Convert `value` to its display `String`. This function is the single formatting seam for
field values, allowing consistent formatting across every message.

The default method uses `string`, which for `AbstractFloat` yields the shortest
representation that round-trips exactly (e.g., `7134.084`, `4.47e-6`), avoiding any loss of
precision in the orbital elements.
"""
_format_value(value) = string(value)

"""
    _push_output!(
        vector::AbstractVector{PrintedField},
        name::String,
        value::Any,
        unit::String
    ) -> Nothing

Push to `vector` the field `(name, value, unit)` if `value` is not `nothing`. The `value`
is converted to a string using [`_format_value`](@ref) and escaped.

Passing the field components as positional arguments lets the compiler specialize on the
value type, avoiding the tuple conversion and boxing of a `Tuple{String, Any, String}`
argument.
"""
function _push_output!(
    vector::AbstractVector{PrintedField},
    name::String,
    value::Any,
    unit::String
)
    isnothing(value) && return nothing
    push!(vector, (name, escape_string(_format_value(value)), unit))
    return nothing
end
