## Description #############################################################################
#
# Show methods.
#
# The rich representation is a tree drawn with the helpers of SatelliteToolboxBase.jl: the
# header, the metadata, and the data are sections, and the data subsections are nested
# under the data. The rows of each section are generated from the label tables below, so
# adding a field only requires a new label.
#
############################################################################################

############################################################################################
#                                        Constants                                         #
############################################################################################

# Labels of the fields displayed in each section, in the display order. The units are
# obtained from `_OMM_FIELD_UNIT` (see `_display_unit`), and the comments are always
# displayed first with the label `Comment`.

const _SHOW_HEADER_LABELS = (
    :classification => "Classification",
    :creation_date  => "Creation Date",
    :originator     => "Originator",
    :message_id     => "Message ID",
)

const _SHOW_METADATA_LABELS = (
    :object_name         => "Object Name",
    :object_id           => "Object ID",
    :center_name         => "Center Name",
    :ref_frame           => "Ref. Frame",
    :ref_frame_epoch     => "Ref. Frame Epoch",
    :time_system         => "Time System",
    :mean_element_theory => "Mean Element Theory",
)

const _SHOW_MEAN_ELEMENTS_LABELS = (
    :epoch             => "Epoch",
    :semi_major_axis   => "Semi-Major Axis",
    :mean_motion       => "Mean Motion",
    :eccentricity      => "Eccentricity",
    :inclination       => "Inclination",
    :raan              => "RA of Asc. Node",
    :arg_of_pericenter => "Arg. of Pericenter",
    :mean_anomaly      => "Mean Anomaly",
    :GM                => "GM",
)

const _SHOW_SPACECRAFT_PARAMETERS_LABELS = (
    :mass            => "Mass",
    :solar_rad_area  => "Solar Rad. Area",
    :solar_rad_coeff => "Solar Rad. Coeff.",
    :drag_area       => "Drag Area",
    :drag_coeff      => "Drag Coefficient",
)

const _SHOW_TLE_PARAMETERS_LABELS = (
    :ephemeris_type      => "Ephemeris Type",
    :classification_type => "Classification Type",
    :norad_cat_id        => "NORAD Cat ID",
    :element_set_number  => "Element Set Number",
    :rev_at_epoch        => "Rev at Epoch",
    :bstar               => "B*",
    :bterm               => "Bterm",
    :mean_motion_dot     => "∂(Mean Motion)/∂t",
    :mean_motion_ddot    => "∂²(Mean Motion)/∂t²",
    :agom                => "AGOM",
)

const _SHOW_COVARIANCE_MATRIX_LABELS = (
    :cov_ref_frame => "Ref. Frame",
    (field => uppercase(String(field)) for field in _OMM_COVARIANCE_MATRIX_FIELDS)...,
)

############################################################################################
#                                        Julia API                                        #
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
    data = omm.data

    # == Header and Metadata ===============================================================

    header_fields = PrintedField[]
    _push_header_fields!(header_fields, omm.header, omm.header.comments)

    metadata_fields = PrintedField[]
    _push_metadata_fields!(metadata_fields, omm.metadata, omm.metadata.comments)

    # == Data ==============================================================================

    data_fields = PrintedField[]
    for comment in data.comments
        _push_output!(data_fields, "Comment", comment, "")
    end

    mean_elements_fields = PrintedField[]
    _push_mean_elements_fields!(mean_elements_fields, data, data.mean_elements_comments)

    spacecraft_fields = PrintedField[]
    _push_spacecraft_parameters_fields!(
        spacecraft_fields, data, data.spacecraft_parameters_comments
    )

    tle_fields = PrintedField[]
    _push_tle_parameters_fields!(tle_fields, data, data.tle_parameters_comments)

    # Binding the `Union` field to a local lets the `isnothing` check narrow its type.
    cov_fields = PrintedField[]
    cov        = data.covariance_matrix
    isnothing(cov) || _push_covariance_matrix_fields!(cov_fields, cov, cov.comments)

    user_fields = PrintedField[]
    for (k, v) in data.user_defined_parameters
        _push_output!(user_fields, k, v, "")
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
    _display_unit(field::Symbol) -> String

Return the unit of the OMM `field` for display: the CCSDS unit of `_OMM_FIELD_UNIT` with
the exponents as superscripts and the degrees as `°`, or an empty string if the field is
dimensionless.
"""
function _display_unit(field::Symbol)
    unit = _omm_field_unit(field)
    isnothing(unit) && return ""
    unit == "deg" && return "°"
    return replace(unit, "**2" => "²", "**3" => "³")
end

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

# Generate one function per label table (e.g. `_push_header_fields!`) that pushes the
# comments of a section, labeled `Comment`, followed by its labeled fields with the units
# given by `_display_unit`. The field accesses are unrolled at code-generation time, so
# they are static and the values are not boxed.
for (name, labels) in (
    (:header, _SHOW_HEADER_LABELS),
    (:metadata, _SHOW_METADATA_LABELS),
    (:mean_elements, _SHOW_MEAN_ELEMENTS_LABELS),
    (:spacecraft_parameters, _SHOW_SPACECRAFT_PARAMETERS_LABELS),
    (:tle_parameters, _SHOW_TLE_PARAMETERS_LABELS),
    (:covariance_matrix, _SHOW_COVARIANCE_MATRIX_LABELS),
)
    fname  = Symbol("_push_", name, "_fields!")
    pushes = [
        :(_push_output!(vector, $label, section.$field, $(_display_unit(field)))) for
        (field, label) in labels
    ]
    docstr = """
            $fname(
                vector::AbstractVector{PrintedField},
                section,
                comments::Vector{String}
            ) -> Nothing

        Push to `vector` the `comments` of the OMM `section`, labeled `Comment`, followed by
        the fields listed in `_SHOW_$(uppercase(String(name)))_LABELS`. Fields whose value
        is `nothing` are skipped.
        """

    @eval @doc $docstr function $fname(
        vector::AbstractVector{PrintedField}, section, comments::Vector{String}
    )
        for comment in comments
            _push_output!(vector, "Comment", comment, "")
        end

        $(pushes...)

        return nothing
    end
end
