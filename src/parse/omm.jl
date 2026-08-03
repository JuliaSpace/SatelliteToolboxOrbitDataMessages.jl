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

    # Parse the file, obtaining the container with the raw field values.
    parsed_omm = _xml_omm__parse(xml, strict)
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

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function parse_omms(str::AbstractString; strict::Bool = true)
    messages = parse_odm(str; strict)

    return OrbitMeanElementsMessage[
        message for message in messages if message isa OrbitMeanElementsMessage
    ]
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# The functions in this section are format-agnostic: the format-specific parsers (e.g. the
# XML one in `./xml/omm.jl`) only convert the input to a container, i.e. a named tuple:
#
#     (; version, header, metadata, data)
#
# where `version` is the OMM format version and `header`, `metadata`, and `data` are named
# tuples with the raw field values of the corresponding sections. The mandatory-field
# validation and the message assembly are performed here from this container. Hence,
# adding a new file type only requires writing the corresponding parser.

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

"""
    _omm_check_mandatory_fields(parsed_omm::NamedTuple) -> Nothing

Check if all mandatory fields of an Orbit Mean-Elements Message (OMM) are present in the
container `parsed_omm` returned by a format-specific parser, throwing an `ArgumentError`
otherwise. The container is a named tuple:

    (; version, header, metadata, data)

where `version` is the OMM format version (2.0 or 3.0) and `header`, `metadata`, and
`data` are named tuples with the raw field values of the corresponding sections.

This function is format-agnostic so that every supported file type is validated by the same
rules.
"""
function _omm_check_mandatory_fields(parsed_omm::NamedTuple)
    version  = parsed_omm.version
    header   = parsed_omm.header
    metadata = parsed_omm.metadata
    data     = parsed_omm.data

    # == Header ============================================================================

    isnothing(header.originator) && throw(ArgumentError(
        "OMM header is missing required field `ORIGINATOR`."
    ))

    if version == v"2.0"
        # The fields `CLASSIFICATION` and `MESSAGE_ID` were introduced in OMM version 3.0.
        !isnothing(header.classification) && throw(ArgumentError(
            "OMM header field `CLASSIFICATION` is not valid in OMM version 2.0."
        ))

        !isnothing(header.message_id) && throw(ArgumentError(
            "OMM header field `MESSAGE_ID` is not valid in OMM version 2.0."
        ))
    end

    # == Metadata ==========================================================================

    for (field, keyword) in _OMM_MANDATORY_METADATA_FIELDS
        isnothing(getproperty(metadata, field)) && throw(ArgumentError(
            "OMM metadata is missing required field `$keyword`."
        ))
    end

    # == Mean Elements =====================================================================

    for (field, keyword) in _OMM_MANDATORY_MEAN_ELEMENTS_FIELDS
        isnothing(getproperty(data, field)) && throw(ArgumentError(
            "OMM data is missing required field `$keyword`."
        ))
    end

    (isnothing(data.semi_major_axis) == isnothing(data.mean_motion)) && throw(ArgumentError(
        "OMM data must contain exactly one of `SEMI_MAJOR_AXIS` and `MEAN_MOTION`."
    ))

    # == TLE Parameters ====================================================================

    # The TLE parameters section is optional, so its rules only apply when the section
    # carries any information.
    if any(field -> !isnothing(getproperty(data, field)), _OMM_TLE_PARAMETER_FIELDS)
        isnothing(data.mean_motion_dot) && throw(ArgumentError(
            "OMM TLE parameters are missing required field `MEAN_MOTION_DOT`."
        ))

        if version == v"2.0"
            # In OMM version 2.0, `BSTAR` and `MEAN_MOTION_DDOT` are required fields, and
            # `BTERM` and `AGOM` do not exist.
            !isnothing(data.bterm) && throw(ArgumentError(
                "OMM TLE parameter `BTERM` is not valid in OMM version 2.0."
            ))

            !isnothing(data.agom) && throw(ArgumentError(
                "OMM TLE parameter `AGOM` is not valid in OMM version 2.0."
            ))

            isnothing(data.bstar) && throw(ArgumentError(
                "OMM TLE parameters are missing required field `BSTAR`."
            ))

            isnothing(data.mean_motion_ddot) && throw(ArgumentError(
                "OMM TLE parameters are missing required field `MEAN_MOTION_DDOT`."
            ))
        else
            (isnothing(data.bstar) == isnothing(data.bterm)) && throw(ArgumentError(
                "OMM TLE parameters must contain exactly one of `BSTAR` and `BTERM`."
            ))

            (isnothing(data.mean_motion_ddot) == isnothing(data.agom)) && throw(
                ArgumentError(
                    "OMM TLE parameters must contain exactly one of `MEAN_MOTION_DDOT` " *
                    "and `AGOM`."
                )
            )
        end
    end

    # == Covariance Matrix =================================================================

    if !isnothing(data.covariance_matrix)
        for field in _OMM_COVARIANCE_MATRIX_FIELDS
            isnothing(getproperty(data.covariance_matrix, field)) && throw(ArgumentError(
                "OMM covariance matrix is missing required element " *
                "`$(uppercase(String(field)))`."
            ))
        end
    end

    return nothing
end

"""
    _omm_assemble(parsed_omm::NamedTuple) -> OrbitMeanElementsMessage

Assemble an Orbit Mean-Elements Message (OMM) from the container `parsed_omm` returned by
a format-specific parser. The container is a named tuple:

    (; version, header, metadata, data)

where `version` is the OMM format version (2.0 or 3.0) and `header`, `metadata`, and
`data` are named tuples with the raw field values of the corresponding sections.

The mandatory fields are validated with [`_omm_check_mandatory_fields`](@ref) before the
message is created.
"""
function _omm_assemble(parsed_omm::NamedTuple)
    _omm_check_mandatory_fields(parsed_omm)

    data = parsed_omm.data

    covariance_matrix = isnothing(data.covariance_matrix) ?
        nothing :
        OmmCovarianceMatrix(; data.covariance_matrix...)

    return OrbitMeanElementsMessage(
        parsed_omm.version,
        OmmHeader(; parsed_omm.header...),
        OmmMetadata(; parsed_omm.metadata...),
        OmmData(; data..., covariance_matrix),
    )
end
