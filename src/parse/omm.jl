## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM).
#
############################################################################################

export parse_omm, parse_omms

"""
    parse_omm(str::AbstractString; kwargs...) -> OrbitMeanElementsMessage

Parse an Orbit Mean-Elements Message (OMM) in the string `str` and return the parsed
message.

If the XML is a Navigation Data Message (NDM), only the first OMM message is returned. An
[`OdmParseError`](@ref) is thrown if the input does not contain an OMM message, is
malformed, or violates the CCSDS 502.0-B-3 rules.

The parsers accommodate the deviations commonly found in real-world files: the XML tags and
the OMM `id` attribute value are matched ignoring the case, empty XML elements are treated
as absent fields, and a missing `CREATION_DATE` yields a message whose creation date is
`nothing`, which cannot be written until a creation date is set.

# Keywords

- `format::Symbol`: The input format. If `:auto`, the format is inferred from the content.
    It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
"""
function parse_omm(str::AbstractString; format::Symbol = :auto)
    str, format = _odm_prepare_input(str, format)

    # Parse the input, obtaining the builder with the raw field values.
    builder = format == :xml ? _xml_omm__parse(str) : _kvn_omm__parse(str)

    # Check the mandatory fields and assemble the message.
    return _omm_assemble(builder)
end

"""
    parse_omms(str::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) in the string `str` and return the
parsed messages.

For XML input, the document can be a stand-alone message or a Navigation Data Message
(NDM): only the OMM messages are returned, and other message types (OPM, OEM, OCM) are
skipped with a warning. If the root tag is not recognized, an [`OdmParseError`](@ref) is
thrown, as for any malformed input. For KVN input, each message must begin with its
`CCSDS_OMM_VERS` keyword. If the input does not contain an OMM message, an empty vector is
returned. See [`parse_omm`](@ref) for the accommodated deviations from the standard.

# Keywords

- `format::Symbol`: The input format. If `:auto`, the format is inferred from the content.
    It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
"""
function parse_omms(str::AbstractString; format::Symbol = :auto)
    str, format = _odm_prepare_input(str, format)

    format == :xml && return _xml_omms__parse(str)

    return _kvn_omms__parse(str)
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# The functions in this section are format-agnostic: the format-specific parsers (e.g. the
# XML one in `./xml/omm.jl`) only fill an `_OmmBuilder` (see `./builder.jl`) with the raw
# field values found in the input. The mandatory-field validation and the message assembly
# are performed here. Hence, adding a new format only requires writing the corresponding
# parser.

# Mandatory fields of the OMM metadata section. Each entry maps the builder field name to
# the CCSDS keyword used in the error message.
const _OMM_MANDATORY_METADATA_FIELDS = (
    (:object_name, "OBJECT_NAME"),
    (:object_id, "OBJECT_ID"),
    (:center_name, "CENTER_NAME"),
    (:ref_frame, "REF_FRAME"),
    (:time_system, "TIME_SYSTEM"),
    (:mean_element_theory, "MEAN_ELEMENT_THEORY"),
)

# Mandatory fields of the OMM mean-elements section. Each entry maps the builder field name
# to the CCSDS keyword used in the error message. The pair `SEMI_MAJOR_AXIS` /
# `MEAN_MOTION` is checked separately since it is a mutually exclusive choice.
const _OMM_MANDATORY_MEAN_ELEMENTS_FIELDS = (
    (:epoch, "EPOCH"),
    (:eccentricity, "ECCENTRICITY"),
    (:inclination, "INCLINATION"),
    (:raan, "RA_OF_ASC_NODE"),
    (:arg_of_pericenter, "ARG_OF_PERICENTER"),
    (:mean_anomaly, "MEAN_ANOMALY"),
)

# Fields with the 21 elements of the OMM covariance matrix, in the field order of
# `OmmCovarianceMatrix`. The CCSDS keyword is the uppercase version of the field name.
const _OMM_COVARIANCE_MATRIX_FIELDS = (
    :cx_x,
    :cy_x,
    :cy_y,
    :cz_x,
    :cz_y,
    :cz_z,
    :cx_dot_x,
    :cx_dot_y,
    :cx_dot_z,
    :cx_dot_x_dot,
    :cy_dot_x,
    :cy_dot_y,
    :cy_dot_z,
    :cy_dot_x_dot,
    :cy_dot_y_dot,
    :cz_dot_x,
    :cz_dot_y,
    :cz_dot_z,
    :cz_dot_x_dot,
    :cz_dot_y_dot,
    :cz_dot_z_dot,
)

# == Keyword Mappings ======================================================================

# The following constants map the CCSDS keywords of each OMM section to the corresponding
# fields of the message structures. They are shared by all format-specific parsers and
# writers. The pairs are stored in the keyword order defined by the CCSDS 502.0-B-3
# standard, which must be preserved when writing messages.

const _OMM_HEADER_KEYWORD_TO_FIELD = Pair{String, Symbol}[
    "CLASSIFICATION" => :classification,
    "CREATION_DATE"  => :creation_date,
    "ORIGINATOR"     => :originator,
    "MESSAGE_ID"     => :message_id,
]

const _OMM_METADATA_KEYWORD_TO_FIELD = Pair{String, Symbol}[
    "OBJECT_NAME"         => :object_name,
    "OBJECT_ID"           => :object_id,
    "CENTER_NAME"         => :center_name,
    "REF_FRAME"           => :ref_frame,
    "REF_FRAME_EPOCH"     => :ref_frame_epoch,
    "TIME_SYSTEM"         => :time_system,
    "MEAN_ELEMENT_THEORY" => :mean_element_theory,
]

const _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD = Pair{String, Symbol}[
    "EPOCH"             => :epoch,
    "SEMI_MAJOR_AXIS"   => :semi_major_axis,
    "MEAN_MOTION"       => :mean_motion,
    "ECCENTRICITY"      => :eccentricity,
    "INCLINATION"       => :inclination,
    "RA_OF_ASC_NODE"    => :raan,
    "ARG_OF_PERICENTER" => :arg_of_pericenter,
    "MEAN_ANOMALY"      => :mean_anomaly,
    "GM"                => :GM,
]

const _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD = Pair{String, Symbol}[
    "MASS"            => :mass,
    "SOLAR_RAD_AREA"  => :solar_rad_area,
    "SOLAR_RAD_COEFF" => :solar_rad_coeff,
    "DRAG_AREA"       => :drag_area,
    "DRAG_COEFF"      => :drag_coeff,
]

const _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD = Pair{String, Symbol}[
    "EPHEMERIS_TYPE"      => :ephemeris_type,
    "CLASSIFICATION_TYPE" => :classification_type,
    "NORAD_CAT_ID"        => :norad_cat_id,
    "ELEMENT_SET_NO"      => :element_set_number,
    "REV_AT_EPOCH"        => :rev_at_epoch,
    "BSTAR"               => :bstar,
    "BTERM"               => :bterm,
    "MEAN_MOTION_DOT"     => :mean_motion_dot,
    "MEAN_MOTION_DDOT"    => :mean_motion_ddot,
    "AGOM"                => :agom,
]

const _OMM_COVARIANCE_KEYWORD_TO_FIELD = Pair{String, Symbol}[
    "COV_REF_FRAME" => :cov_ref_frame,
    (uppercase(String(field)) => field for field in _OMM_COVARIANCE_MATRIX_FIELDS)...,
]

# Physical units of the OMM fields as defined by the CCSDS 502.0-B-3 standard. Fields that
# are not listed here (e.g. dates and dimensionless quantities) have no unit annotation.
const _OMM_FIELD_UNIT = Dict{Symbol, String}(
    :semi_major_axis   => "km",
    :mean_motion       => "rev/day",
    :inclination       => "deg",
    :raan              => "deg",
    :arg_of_pericenter => "deg",
    :mean_anomaly      => "deg",
    :GM                => "km**3/s**2",
    :mass              => "kg",
    :solar_rad_area    => "m**2",
    :drag_area         => "m**2",
    :bstar             => "1/ER",
    :bterm             => "m**2/kg",
    :mean_motion_dot   => "rev/day**2",
    :mean_motion_ddot  => "rev/day**3",
    :agom              => "m**2/kg",
    :cx_x              => "km**2",
    :cy_x              => "km**2",
    :cy_y              => "km**2",
    :cz_x              => "km**2",
    :cz_y              => "km**2",
    :cz_z              => "km**2",
    :cx_dot_x          => "km**2/s",
    :cx_dot_y          => "km**2/s",
    :cx_dot_z          => "km**2/s",
    :cx_dot_x_dot      => "km**2/s**2",
    :cy_dot_x          => "km**2/s",
    :cy_dot_y          => "km**2/s",
    :cy_dot_z          => "km**2/s",
    :cy_dot_x_dot      => "km**2/s**2",
    :cy_dot_y_dot      => "km**2/s**2",
    :cz_dot_x          => "km**2/s",
    :cz_dot_y          => "km**2/s",
    :cz_dot_z          => "km**2/s",
    :cz_dot_x_dot      => "km**2/s**2",
    :cz_dot_y_dot      => "km**2/s**2",
    :cz_dot_z_dot      => "km**2/s**2",
)

"""
    _omm_field_unit(field::Symbol) -> Union{Nothing, String}

Return the physical unit of the OMM `field` as defined in `_OMM_FIELD_UNIT`, or `nothing` if
the field is dimensionless.
"""
_omm_field_unit(field::Symbol) = get(_OMM_FIELD_UNIT, field, nothing)

"""
    _omm_parse_field(
        ::Type{T},
        value::AbstractString,
        keyword::AbstractString
    ) -> Union{Nothing, T}

Parse the raw `value` of the OMM field identified by the CCSDS `keyword` as type `T`,
throwing an `OdmParseError` that names the keyword if the value is invalid.

String values are kept verbatim, whereas the other types ignore a trailing `[unit]`
annotation, which the KVN format allows after the value (see [`_kvn__strip_unit`](@ref)).
The `NanoDate` method returns `nothing` when `value` is empty or contains only whitespace.
"""
_omm_parse_field(::Type{String}, value::AbstractString, keyword::AbstractString) =
    String(value)

function _omm_parse_field(::Type{NanoDate}, value::AbstractString, keyword::AbstractString)
    try
        return _parse_ndm_date(_kvn__strip_unit(value))
    catch e
        e isa ArgumentError || rethrow()
        throw(
            OdmParseError(
                "OMM field `$keyword` contains an invalid date: \"$value\"."; keyword
            ),
        )
    end
end

function _omm_parse_field(::Type{Char}, value::AbstractString, keyword::AbstractString)
    value = _kvn__strip_unit(value)

    length(value) == 1 || throw(
        OdmParseError("OMM field `$keyword` must contain exactly one character."; keyword),
    )

    return only(value)
end

function _omm_parse_field(
    ::Type{T}, value::AbstractString, keyword::AbstractString
) where {T <: Number}
    number = tryparse(T, _kvn__strip_unit(value))

    isnothing(number) && throw(
        OdmParseError(
            "OMM field `$keyword` contains an invalid value: \"$value\"."; keyword
        ),
    )

    return number
end

"""
    _omm_check_mandatory_fields(version::VersionNumber, builder::_OmmBuilder) -> Nothing

Check if all mandatory fields of an Orbit Mean-Elements Message (OMM) with `version` (2.0 or
3.0) are present in the `builder` filled by a format-specific parser, throwing an
`OdmParseError` otherwise. The `CREATION_DATE` is not required, allowing real-world files
with an omitted creation date to be processed.

This function is format-agnostic so that every supported format is validated by the same
rules.
"""
function _omm_check_mandatory_fields(version::VersionNumber, builder::_OmmBuilder)
    header   = builder.header
    metadata = builder.metadata
    data     = builder.data

    # == Header ============================================================================

    # In OMM version 2.0, we allow a blank `ORIGINATOR` to accommodate real-world files
    # (e.g. from Celestrak) that omit its value.
    (version != v"2.0") && isnothing(header.originator) &&
        throw(OdmParseError("OMM header is missing required field `ORIGINATOR`."))

    if version == v"2.0"
        # The fields `CLASSIFICATION` and `MESSAGE_ID` were introduced in OMM version 3.0.
        isnothing(header.classification) || throw(
            OdmParseError(
                "OMM header field `CLASSIFICATION` is not valid in OMM version 2.0."
            ),
        )

        isnothing(header.message_id) || throw(
            OdmParseError("OMM header field `MESSAGE_ID` is not valid in OMM version 2.0."),
        )
    end

    # == Metadata ==========================================================================

    for (field, keyword) in _OMM_MANDATORY_METADATA_FIELDS
        isnothing(getfield(metadata, field)) &&
            throw(OdmParseError("OMM metadata is missing required field `$keyword`."))
    end

    # == Mean Elements =====================================================================

    for (field, keyword) in _OMM_MANDATORY_MEAN_ELEMENTS_FIELDS
        isnothing(getfield(data, field)) &&
            throw(OdmParseError("OMM data is missing required field `$keyword`."))
    end

    (isnothing(data.semi_major_axis) == isnothing(data.mean_motion)) && throw(
        OdmParseError(
            "OMM data must contain exactly one of `SEMI_MAJOR_AXIS` and `MEAN_MOTION`."
        ),
    )

    # == TLE Parameters ====================================================================

    # The TLE parameters section is optional, so its rules only apply when the section
    # carries any information. The predicate must match the one used by the
    # `OrbitMeanElementsMessage` constructor, which also treats a comments-only section as
    # present.
    has_tle_parameters =
        !isempty(data.tle_parameters_comments) || any(
            !isnothing,
            (
                data.ephemeris_type,
                data.classification_type,
                data.norad_cat_id,
                data.element_set_number,
                data.rev_at_epoch,
                data.bstar,
                data.bterm,
                data.mean_motion_dot,
                data.mean_motion_ddot,
                data.agom,
            ),
        )

    if has_tle_parameters
        isnothing(data.mean_motion_dot) && throw(
            OdmParseError(
                "OMM TLE parameters are missing required field `MEAN_MOTION_DOT`."
            ),
        )

        if version == v"2.0"
            # In OMM version 2.0, `BSTAR` and `MEAN_MOTION_DDOT` are required fields, and
            # `BTERM` and `AGOM` do not exist.
            isnothing(data.bterm) || throw(
                OdmParseError("OMM TLE parameter `BTERM` is not valid in OMM version 2.0."),
            )

            isnothing(data.agom) || throw(
                OdmParseError("OMM TLE parameter `AGOM` is not valid in OMM version 2.0."),
            )

            isnothing(data.bstar) && throw(
                OdmParseError("OMM TLE parameters are missing required field `BSTAR`.")
            )

            isnothing(data.mean_motion_ddot) && throw(
                OdmParseError(
                    "OMM TLE parameters are missing required field `MEAN_MOTION_DDOT`."
                ),
            )
        else
            (isnothing(data.bstar) == isnothing(data.bterm)) && throw(
                OdmParseError(
                    "OMM TLE parameters must contain exactly one of `BSTAR` and `BTERM`.",
                ),
            )

            (isnothing(data.mean_motion_ddot) == isnothing(data.agom)) && throw(
                OdmParseError(
                    "OMM TLE parameters must contain exactly one of `MEAN_MOTION_DDOT` " *
                    "and `AGOM`.",
                ),
            )
        end
    end

    # == Covariance Matrix =================================================================

    covariance_matrix = data.covariance_matrix

    if !isnothing(covariance_matrix)
        for field in _OMM_COVARIANCE_MATRIX_FIELDS
            isnothing(getfield(covariance_matrix, field)) && throw(
                OdmParseError(
                    "OMM covariance matrix is missing required element " *
                    "`$(uppercase(String(field)))`.",
                ),
            )
        end
    end

    return nothing
end

"""
    _omm_assemble(builder::_OmmBuilder) -> OrbitMeanElementsMessage

Assemble an Orbit Mean-Elements Message (OMM) from the `builder` filled by a
format-specific parser.

The version and the mandatory fields are validated before the message is created. Then,
each section is built from the corresponding builder.
"""
function _omm_assemble(builder::_OmmBuilder)
    # == Version ===========================================================================

    version = builder.version

    isnothing(version) && throw(
        OdmParseError(
            "The OMM is missing the required format version (the KVN `CCSDS_OMM_VERS` " *
            "keyword or the XML `version` attribute).",
        ),
    )

    version ∈ (2.0, 3.0) || throw(OdmParseError("Unsupported OMM version: $version."))

    omm_version = version == 2.0 ? v"2.0" : v"3.0"

    # == Mandatory Fields ==================================================================

    _omm_check_mandatory_fields(omm_version, builder)

    # == Assembling ========================================================================

    # The `ORIGINATOR` may be absent in OMM version 2.0 (see
    # `_omm_check_mandatory_fields`). Since the header structure requires it, we default
    # the value to an empty string.
    isnothing(builder.header.originator) && (builder.header.originator = "")

    return OrbitMeanElementsMessage(
        omm_version,
        _omm_build(OmmHeader, builder.header),
        _omm_build(OmmMetadata, builder.metadata),
        _omm_build(OmmData, builder.data),
    )
end
