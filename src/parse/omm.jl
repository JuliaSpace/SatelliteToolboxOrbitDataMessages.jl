## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM).
#
############################################################################################

export parse_omm, parse_omms

"""
    parse_omm(str::AbstractString; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Parse an Orbit Mean-Elements Message (OMM) in the string `str` and return the parsed
message.

If the XML is a Navigation Data Message (NDM), only the first OMM message is returned. If
the file does not contain an OMM message, `nothing` is returned.

# Keywords

- `file_type::Symbol`: The input file type. If `:auto`, the file type is inferred from the
    content. It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omm(str::AbstractString; file_type::Symbol = :auto, strict::Bool = true)
    if file_type == :auto
        file_type = occursin(r"^\s*<", str) ? :xml : :kvn
    end

    # Parse the file, obtaining the container with the raw field values.
    parsed_omm = if file_type == :xml
        _xml_omm__parse(str, strict)
    elseif file_type == :kvn
        _kvn_omm__parse(str)
    else
        throw(ArgumentError("Unsupported file type: $file_type."))
    end

    isnothing(parsed_omm) && return nothing

    # Check the mandatory fields and assemble the message.
    return _omm_assemble(parsed_omm)
end

"""
    parse_omms(str::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) in the string `str` and return the
parsed messages. The input format must be XML.

If the XML is a Navigation Data Message (NDM), only the OMM messages are returned; other
message types (OPM, OEM, OCM) are skipped with a warning. If the document does not contain
an OMM message, an empty vector is returned. If the root tag is not recognized, an
`ArgumentError` is thrown.

# Keywords

- `file_type::Symbol`: The input file type. If `:auto`, the file type is inferred from the
    content. It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omms(str::AbstractString; file_type::Symbol = :auto, strict::Bool = true)
    if file_type == :auto
        file_type = occursin(r"^\s*<", str) ? :xml : :kvn
    end

    file_type == :kvn && return _kvn_omms__parse(str)
    file_type == :xml && return _xml_omms__parse(str, strict)

    return throw(ArgumentError("Unsupported file type: $file_type."))
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# The functions in this section are format-agnostic: the format-specific parsers (e.g. the
# XML one in `./xml/omm.jl`) only convert the input to four pieces of information:
#
#   - `version::Union{Nothing, Float64}`: The OMM format version.
#   - `header_fields::Dict{Symbol, Any}`: The raw field values of the header section.
#   - `metadata_fields::Dict{Symbol, Any}`: The raw field values of the metadata section.
#   - `data_fields::Dict{Symbol, Any}`: The raw field values of the data section.
#
# The dictionaries only contain the fields that are present in the input. The
# mandatory-field validation and the message assembly are performed here by converting the
# dictionaries to keyword arguments of the OMM section constructors. Hence, adding a new
# file type only requires writing the corresponding parser.

# Mandatory fields of the OMM metadata section. Each entry maps the parsed field name to
# the CCSDS keyword used in the error message.
const _OMM_MANDATORY_METADATA_FIELDS = (
    (:object_name,         "OBJECT_NAME"),
    (:object_id,           "OBJECT_ID"),
    (:center_name,         "CENTER_NAME"),
    (:ref_frame,           "REF_FRAME"),
    (:time_system,         "TIME_SYSTEM"),
    (:mean_element_theory, "MEAN_ELEMENT_THEORY"),
)

# Mandatory fields of the OMM mean-elements section. Each entry maps the parsed field name
# to the CCSDS keyword used in the error message. The pair `SEMI_MAJOR_AXIS` /
# `MEAN_MOTION` is checked separately since it is a mutually exclusive choice.
const _OMM_MANDATORY_MEAN_ELEMENTS_FIELDS = (
    (:epoch,             "EPOCH"),
    (:eccentricity,      "ECCENTRICITY"),
    (:inclination,       "INCLINATION"),
    (:raan,              "RA_OF_ASC_NODE"),
    (:arg_of_pericenter, "ARG_OF_PERICENTER"),
    (:mean_anomaly,      "MEAN_ANOMALY"),
)

# Fields of the OMM TLE parameters section. They are used to detect whether the section
# carries any information, in which case its mandatory-field rules apply.
const _OMM_TLE_PARAMETER_FIELDS = (
    :ephemeris_type,
    :classification_type,
    :norad_cat_id,
    :element_set_number,
    :rev_at_epoch,
    :bstar,
    :bterm,
    :mean_motion_dot,
    :mean_motion_ddot,
    :agom,
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
# fields of the message structures. They are shared by all format-specific parsers. The
# pairs are stored in the keyword order defined by the CCSDS 502.0-B-3 standard, which
# must be preserved when writing messages.

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

# All the OMM keywords merged into a single mapping from the CCSDS keyword to the section
# index and the corresponding message field. The section index refers to the section order
# used by the KVN parser (see `_kvn_omm__parse`): 1) header, 2) metadata, 3) mean
# elements, 4) spacecraft parameters, 5) TLE parameters, and 6) covariance matrix. The
# per-section mappings above are required by formats with a nested structure (e.g. XML),
# whereas flat formats (e.g. KVN) can use this merged mapping to resolve any keyword with
# a single lookup.
const _OMM_KVN_KEYWORD_TO_SECTION_AND_FIELD = Dict{String, Tuple{Int, Symbol}}(
    (k => (1, f) for (k, f) in _OMM_HEADER_KEYWORD_TO_FIELD)...,
    (k => (2, f) for (k, f) in _OMM_METADATA_KEYWORD_TO_FIELD)...,
    (k => (3, f) for (k, f) in _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD)...,
    (k => (4, f) for (k, f) in _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD)...,
    (k => (5, f) for (k, f) in _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD)...,
    (k => (6, f) for (k, f) in _OMM_COVARIANCE_KEYWORD_TO_FIELD)...,
)

# Types of the OMM fields. Fields that are not listed here are `Float64`.
const _OMM_FIELD_TYPE = Dict{Symbol, DataType}(
    :classification      => String,
    :creation_date       => NanoDate,
    :originator          => String,
    :message_id          => String,
    :object_name         => String,
    :object_id           => String,
    :center_name         => String,
    :ref_frame           => String,
    :ref_frame_epoch     => NanoDate,
    :time_system         => String,
    :mean_element_theory => String,
    :epoch               => NanoDate,
    :ephemeris_type      => Int,
    :classification_type => Char,
    :norad_cat_id        => Int,
    :element_set_number  => Int,
    :rev_at_epoch        => Int,
    :cov_ref_frame       => String,
)

"""
    _omm_field_type(field::Symbol) -> DataType

Return the type of the OMM `field` as defined in `_OMM_FIELD_TYPE`, defaulting to
`Float64`.
"""
_omm_field_type(field::Symbol) = get(_OMM_FIELD_TYPE, field, Float64)

"""
    _omm_parse_field(::Type{T}, value::AbstractString, keyword::AbstractString) -> T

Parse the raw `value` of the OMM field identified by the CCSDS `keyword` as type `T`,
throwing an `ArgumentError` that names the keyword if the value is invalid.
"""
_omm_parse_field(::Type{String}, value::AbstractString, keyword::AbstractString) =
    String(value)

function _omm_parse_field(
    ::Type{NanoDate},
    value::AbstractString,
    keyword::AbstractString
)
    return _parse_ndm_date(value)
end

function _omm_parse_field(::Type{Char}, value::AbstractString, keyword::AbstractString)
    length(value) == 1 || throw(ArgumentError(
        "OMM field `$keyword` must contain exactly one character."
    ))

    return only(value)
end

function _omm_parse_field(
    ::Type{T},
    value::AbstractString,
    keyword::AbstractString
) where T <: Number
    number = tryparse(T, value)

    isnothing(number) && throw(ArgumentError(
        "OMM field `$keyword` contains an invalid value: \"$value\"."
    ))

    return number
end

"""
    _omm_check_mandatory_fields(version::VersionNumber, header_fields::Dict{Symbol, Any}, metadata_fields::Dict{Symbol, Any}, data_fields::Dict{Symbol, Any}) -> Nothing

Check if all mandatory fields of an Orbit Mean-Elements Message (OMM) with `version` (2.0
or 3.0) are present in the dictionaries `header_fields`, `metadata_fields`, and
`data_fields` returned by a format-specific parser, throwing an `ArgumentError` otherwise.
A field whose value is `nothing` is treated as absent.

This function is format-agnostic so that every supported file type is validated by the same
rules.
"""
function _omm_check_mandatory_fields(
    version::VersionNumber,
    header_fields::Dict{Symbol, Any},
    metadata_fields::Dict{Symbol, Any},
    data_fields::Dict{Symbol, Any}
)
    # == Header ============================================================================

    isnothing(get(header_fields, :originator, nothing)) && throw(ArgumentError(
        "OMM header is missing required field `ORIGINATOR`."
    ))

    if version == v"2.0"
        # The fields `CLASSIFICATION` and `MESSAGE_ID` were introduced in OMM version 3.0.
        !isnothing(get(header_fields, :classification, nothing)) && throw(ArgumentError(
            "OMM header field `CLASSIFICATION` is not valid in OMM version 2.0."
        ))

        !isnothing(get(header_fields, :message_id, nothing)) && throw(ArgumentError(
            "OMM header field `MESSAGE_ID` is not valid in OMM version 2.0."
        ))
    end

    # == Metadata ==========================================================================

    for (field, keyword) in _OMM_MANDATORY_METADATA_FIELDS
        isnothing(get(metadata_fields, field, nothing)) && throw(ArgumentError(
            "OMM metadata is missing required field `$keyword`."
        ))
    end

    # == Mean Elements =====================================================================

    for (field, keyword) in _OMM_MANDATORY_MEAN_ELEMENTS_FIELDS
        isnothing(get(data_fields, field, nothing)) && throw(ArgumentError(
            "OMM data is missing required field `$keyword`."
        ))
    end

    semi_major_axis = get(data_fields, :semi_major_axis, nothing)
    mean_motion     = get(data_fields, :mean_motion, nothing)

    (isnothing(semi_major_axis) == isnothing(mean_motion)) && throw(ArgumentError(
        "OMM data must contain exactly one of `SEMI_MAJOR_AXIS` and `MEAN_MOTION`."
    ))

    # == TLE Parameters ====================================================================

    bstar            = get(data_fields, :bstar, nothing)
    bterm            = get(data_fields, :bterm, nothing)
    mean_motion_dot  = get(data_fields, :mean_motion_dot, nothing)
    mean_motion_ddot = get(data_fields, :mean_motion_ddot, nothing)
    agom             = get(data_fields, :agom, nothing)

    # The TLE parameters section is optional, so its rules only apply when the section
    # carries any information.
    if any(field -> !isnothing(get(data_fields, field, nothing)), _OMM_TLE_PARAMETER_FIELDS)
        isnothing(mean_motion_dot) && throw(ArgumentError(
            "OMM TLE parameters are missing required field `MEAN_MOTION_DOT`."
        ))

        if version == v"2.0"
            # In OMM version 2.0, `BSTAR` and `MEAN_MOTION_DDOT` are required fields, and
            # `BTERM` and `AGOM` do not exist.
            !isnothing(bterm) && throw(ArgumentError(
                "OMM TLE parameter `BTERM` is not valid in OMM version 2.0."
            ))

            !isnothing(agom) && throw(ArgumentError(
                "OMM TLE parameter `AGOM` is not valid in OMM version 2.0."
            ))

            isnothing(bstar) && throw(ArgumentError(
                "OMM TLE parameters are missing required field `BSTAR`."
            ))

            isnothing(mean_motion_ddot) && throw(ArgumentError(
                "OMM TLE parameters are missing required field `MEAN_MOTION_DDOT`."
            ))
        else
            (isnothing(bstar) == isnothing(bterm)) && throw(ArgumentError(
                "OMM TLE parameters must contain exactly one of `BSTAR` and `BTERM`."
            ))

            (isnothing(mean_motion_ddot) == isnothing(agom)) && throw(
                ArgumentError(
                    "OMM TLE parameters must contain exactly one of `MEAN_MOTION_DDOT` " *
                    "and `AGOM`."
                )
            )
        end
    end

    # == Covariance Matrix =================================================================

    covariance_fields = get(data_fields, :covariance_matrix, nothing)

    if !isnothing(covariance_fields)
        for field in _OMM_COVARIANCE_MATRIX_FIELDS
            isnothing(get(covariance_fields, field, nothing)) && throw(ArgumentError(
                "OMM covariance matrix is missing required element " *
                "`$(uppercase(String(field)))`."
            ))
        end
    end

    return nothing
end

"""
    _omm_assemble(version::Union{Nothing, Float64}, header_fields::Dict{Symbol, Any}, metadata_fields::Dict{Symbol, Any}, data_fields::Dict{Symbol, Any}) -> OrbitMeanElementsMessage

Assemble an Orbit Mean-Elements Message (OMM) from the information returned by a
format-specific parser: the format `version` (`nothing` if it is absent in the input) and
the dictionaries `header_fields`, `metadata_fields`, and `data_fields` with the raw field
values of the corresponding sections. The dictionaries only contain the fields that are
present in the input.

The version and the mandatory fields are validated before the message is created. Then,
each dictionary is converted to keyword arguments of the corresponding OMM section
constructor. The covariance matrix, if present, must be stored in
`data_fields[:covariance_matrix]` as a `Dict{Symbol, Any}` with its raw element values.

    _omm_assemble(parsed_omm::NamedTuple) -> OrbitMeanElementsMessage

Assemble an OMM from the container `(; version, header_fields, metadata_fields,
data_fields)` holding the same information.
"""
function _omm_assemble(
    version::Union{Nothing, Float64},
    header_fields::Dict{Symbol, Any},
    metadata_fields::Dict{Symbol, Any},
    data_fields::Dict{Symbol, Any}
)
    # == Version ===========================================================================

    isnothing(version) && throw(ArgumentError(
        "The OMM is missing the required format version (`CCSDS_OMM_VERS`)."
    ))

    version ∈ (2.0, 3.0) || throw(ArgumentError("Unsupported OMM version: $version."))

    omm_version = VersionNumber(string(version))

    # == Mandatory Fields ==================================================================

    _omm_check_mandatory_fields(omm_version, header_fields, metadata_fields, data_fields)

    # == Assembling ========================================================================

    covariance_fields = get(data_fields, :covariance_matrix, nothing)

    !isnothing(covariance_fields) &&
        (data_fields[:covariance_matrix] = OmmCovarianceMatrix(; covariance_fields...))

    return OrbitMeanElementsMessage(
        omm_version,
        OmmHeader(; header_fields...),
        OmmMetadata(; metadata_fields...),
        OmmData(; data_fields...),
    )
end

function _omm_assemble(parsed_omm::NamedTuple)
    return _omm_assemble(
        parsed_omm.version,
        parsed_omm.header_fields,
        parsed_omm.metadata_fields,
        parsed_omm.data_fields
    )
end
