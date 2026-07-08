## Description #############################################################################
#
# Definition of types and constructors for Orbit Mean-Elements Messages (OMM).
#
## References ##############################################################################
#
# [1] CCSDS 502.0-B-3 (2023). Orbit Data Messages. CCSDS Secretariat, Issue 3. Washington,
#     DC, USA.
#
############################################################################################

export OrbitMeanElementsMessage

# == Types =================================================================================

# -- Header --------------------------------------------------------------------------------

@kwdef struct OmmHeader
    comment::Union{String, Nothing} = nothing
    classification::Union{String, Nothing} = nothing
    creation_date::NanoDate
    originator::String
    message_id::Union{String, Nothing} = nothing
end

# -- Metadata ------------------------------------------------------------------------------

@kwdef struct OmmMetadata
    comment::Union{String, Nothing} = nothing
    object_name::String
    object_id::String
    center_name::String
    ref_frame::String
    ref_frame_epoch::Union{NanoDate, Nothing} = nothing
    time_system::String
    mean_element_theory::String
end

# -- Data ----------------------------------------------------------------------------------

@kwdef struct OmmData
    # == Mean Keplerian Elements ===========================================================

    data_comment::Union{String, Nothing} = nothing
    epoch::NanoDate
    semi_major_axis::Union{Float64, Nothing} = nothing
    mean_motion::Union{Float64, Nothing} = nothing
    eccentricity::Float64
    inclination::Float64
    raan::Float64
    arg_of_pericenter::Float64
    mean_anomaly::Float64
    GM::Union{Float64, Nothing} = nothing

    # == Spacecraft Data ===================================================================

    spacecraft_data_comment::Union{String, Nothing} = nothing
    mass::Union{Float64, Nothing} = nothing
    solar_rad_area::Union{Float64, Nothing} = nothing
    solar_rad_coeff::Union{Float64, Nothing} = nothing
    drag_area::Union{Float64, Nothing} = nothing
    drag_coeff::Union{Float64, Nothing} = nothing

    # == TLE Related Parameters ===========================================================

    tle_parameters_comment::Union{String, Nothing} = nothing
    ephemeris_type::Union{Int, Nothing} = nothing
    classification_type::Union{Char, Nothing} = nothing
    norad_cat_id::Union{Int, Nothing} = nothing
    element_set_number::Union{Int, Nothing} = nothing
    rev_at_epoch::Union{Int, Nothing} = nothing
    bstar::Union{Float64, Nothing} = nothing
    mean_motion_dot::Union{Float64, Nothing} = nothing
    mean_motion_ddot::Union{Float64, Nothing} = nothing

    # == Covariance Matrix =================================================================

    # TODO: Support covariance matrix.

    # == User-Defined Parameters ===========================================================

    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}} = nothing
end

# -- Segment -------------------------------------------------------------------------------

@kwdef struct OmmSegment
    metadata::OmmMetadata
    data::OmmData
end

# -- Body ----------------------------------------------------------------------------------

@kwdef struct OmmBody
    segment::OmmSegment
end

# -- OMM -----------------------------------------------------------------------------------

"""
    struct OrbitMeanElementsMessage <: OrbitDataMessage

Orbit Mean-Elements Message (OMM) as defined by the CCSDS 502.0-B-3 standard.

The structure follows the nested hierarchy of the standard: a `header`, and a `body` that
contains a segment with the metadata and data sections. The individual fields can be
accessed through this hierarchy, for example `omm.body.segment.metadata.object_name` or
`omm.body.segment.data.epoch`.

To create a message, use the keyword constructor `OrbitMeanElementsMessage(; kwargs...)`,
which assembles all the internal sections automatically.

# Fields

- `version::VersionNumber`: OMM format version (2.0 or 3.0).
- `header::OmmHeader`: Message header (creation date, originator, etc.).
- `body::OmmBody`: Message body containing the metadata and the mean elements data.
"""
struct OrbitMeanElementsMessage <: OrbitDataMessage
    version::VersionNumber
    header::OmmHeader
    body::OmmBody
end

# == Constructors ==========================================================================

"""
    OrbitMeanElementsMessage(; kwargs...) -> OrbitMeanElementsMessage

Create an Orbit Mean-Elements Message (OMM) from the keyword arguments `kwargs...`.

This constructor assembles the internal header, metadata, and data sections defined by the
CCSDS 502.0-B-3 standard, returning a message compatible with version 3.0. The required
keywords are the message originator, the object identification, the reference frame and
time system, and the mean Keplerian elements. All angular quantities (`inclination`,
`raan`, `arg_of_pericenter`, and `mean_anomaly`) are expressed in **degrees**.

The date keywords (`creation_date`, `epoch`, and `ref_frame_epoch`) must be provided as
`NanoDate` objects so that the sub-second precision is preserved.

# Keywords

- `header_comment::Union{String, Nothing}`: Comment for the header section.
    (**Default**: `nothing`)
- `classification::Union{String, Nothing}`: Message classification.
    (**Default**: `nothing`)
- `creation_date::NanoDate`: Message creation date (**required**).
- `originator::String`: Message originator (**required**).
- `message_id::Union{String, Nothing}`: Unique message identifier.
    (**Default**: `nothing`)
- `metadata_comment::Union{String, Nothing}`: Comment for the metadata section.
    (**Default**: `nothing`)
- `object_name::String`: Spacecraft name (**required**).
- `object_id::String`: International designator, usually in the format `YYYY-NNNP`
    (**required**).
- `center_name::String`: Origin of the reference frame (**required**).
- `ref_frame::String`: Reference frame of the mean elements (**required**).
- `ref_frame_epoch::Union{NanoDate, Nothing}`: Epoch of the reference frame, if it is not
    intrinsic to its definition.
    (**Default**: `nothing`)
- `time_system::String`: Time system used for the message (**required**).
- `mean_element_theory::String`: Theory describing the mean elements, e.g. `"SGP4"`
    (**required**).
- `data_comment::Union{String, Nothing}`: Comment for the mean elements section.
    (**Default**: `nothing`)
- `epoch::NanoDate`: Epoch of the mean Keplerian elements (**required**).
- `semi_major_axis::Union{Float64, Nothing}`: Semi-major axis [km]. Either this keyword or
    `mean_motion` must be provided.
    (**Default**: `nothing`)
- `mean_motion::Union{Float64, Nothing}`: Mean motion [rev/day]. Either this keyword or
    `semi_major_axis` must be provided.
    (**Default**: `nothing`)
- `eccentricity::Float64`: Eccentricity (**required**).
- `inclination::Float64`: Inclination [deg] (**required**).
- `raan::Float64`: Right ascension of the ascending node [deg] (**required**).
- `arg_of_pericenter::Float64`: Argument of pericenter [deg] (**required**).
- `mean_anomaly::Float64`: Mean anomaly [deg] (**required**).
- `GM::Union{Float64, Nothing}`: Gravitational coefficient [km³/s²].
    (**Default**: `nothing`)
- `spacecraft_data_comment::Union{String, Nothing}`: Comment for the spacecraft data
    section.
    (**Default**: `nothing`)
- `mass::Union{Float64, Nothing}`: Spacecraft mass [kg].
    (**Default**: `nothing`)
- `solar_rad_area::Union{Float64, Nothing}`: Effective area for solar radiation pressure
    [m²].
    (**Default**: `nothing`)
- `solar_rad_coeff::Union{Float64, Nothing}`: Solar radiation pressure coefficient.
    (**Default**: `nothing`)
- `drag_area::Union{Float64, Nothing}`: Effective area for atmospheric drag [m²].
    (**Default**: `nothing`)
- `drag_coeff::Union{Float64, Nothing}`: Atmospheric drag coefficient.
    (**Default**: `nothing`)
- `tle_parameters_comment::Union{String, Nothing}`: Comment for the TLE-related parameters
    section.
    (**Default**: `nothing`)
- `ephemeris_type::Union{Int, Nothing}`: Default ephemeris type associated with the TLE.
    (**Default**: `nothing`)
- `classification_type::Union{Char, Nothing}`: Classification type, e.g. `'U'` for
    unclassified.
    (**Default**: `nothing`)
- `norad_cat_id::Union{Int, Nothing}`: NORAD catalog number.
    (**Default**: `nothing`)
- `element_set_number::Union{Int, Nothing}`: Element set number.
    (**Default**: `nothing`)
- `rev_at_epoch::Union{Int, Nothing}`: Revolution number at epoch.
    (**Default**: `nothing`)
- `bstar::Union{Float64, Nothing}`: SGP4 drag term (B*) [1/earth radii].
    (**Default**: `nothing`)
- `mean_motion_dot::Union{Float64, Nothing}`: First time derivative of the mean motion
    [rev/day²].
    (**Default**: `nothing`)
- `mean_motion_ddot::Union{Float64, Nothing}`: Second time derivative of the mean motion
    [rev/day³].
    (**Default**: `nothing`)
- `user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}}`: User-defined
    parameters as a vector of `key => value` pairs.
    (**Default**: `nothing`)

    OrbitMeanElementsMessage(omm::OrbitMeanElementsMessage; kwargs...) -> OrbitMeanElementsMessage

Create a copy of `omm`, overriding the fields specified in `kwargs...`. Any keyword accepted
by the main constructor can be used; the remaining fields are copied from `omm`.
"""
function OrbitMeanElementsMessage(
    ;
    # == Header ============================================================================
    header_comment::Union{String, Nothing} = nothing,
    classification::Union{String, Nothing} = nothing,
    creation_date::NanoDate,
    originator::String,
    message_id::Union{String, Nothing} = nothing,

    # == Metadata ==========================================================================
    metadata_comment::Union{String, Nothing} = nothing,
    object_name::String,
    object_id::String,
    center_name::String,
    ref_frame::String,
    ref_frame_epoch::Union{NanoDate, Nothing} = nothing,
    time_system::String,
    mean_element_theory::String,

    # == Data =============================================================================

    # -- Mean Keplerian Elements -----------------------------------------------------------

    data_comment::Union{String, Nothing} = nothing,
    epoch::NanoDate,
    semi_major_axis::Union{Float64, Nothing} = nothing,
    mean_motion::Union{Float64, Nothing} = nothing,
    eccentricity::Float64,
    inclination::Float64,
    raan::Float64,
    arg_of_pericenter::Float64,
    mean_anomaly::Float64,
    GM::Union{Float64, Nothing} = nothing,

    # -- Spacecraft Data -------------------------------------------------------------------

    spacecraft_data_comment::Union{String, Nothing} = nothing,
    mass::Union{Float64, Nothing} = nothing,
    solar_rad_area::Union{Float64, Nothing} = nothing,
    solar_rad_coeff::Union{Float64, Nothing} = nothing,
    drag_area::Union{Float64, Nothing} = nothing,
    drag_coeff::Union{Float64, Nothing} = nothing,

    # -- TLE Related Parameters ------------------------------------------------------------

    tle_parameters_comment::Union{String, Nothing} = nothing,
    ephemeris_type::Union{Int, Nothing} = nothing,
    classification_type::Union{Char, Nothing} = nothing,
    norad_cat_id::Union{Int, Nothing} = nothing,
    element_set_number::Union{Int, Nothing} = nothing,
    rev_at_epoch::Union{Int, Nothing} = nothing,
    bstar::Union{Float64, Nothing} = nothing,
    mean_motion_dot::Union{Float64, Nothing} = nothing,
    mean_motion_ddot::Union{Float64, Nothing} = nothing,

    # -- User-Defined Parameters -----------------------------------------------------------

    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}} = nothing
)
    header = OmmHeader(
        ;
        comment = header_comment,
        classification,
        creation_date,
        originator,
        message_id,
    )

    metadata = OmmMetadata(
        ;
        comment = metadata_comment,
        object_name,
        object_id,
        center_name,
        ref_frame,
        ref_frame_epoch,
        time_system,
        mean_element_theory,
    )

    data = OmmData(
        ;
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
        user_defined_parameters,
    )

    segment = OmmSegment(metadata, data)

    body = OmmBody(segment)

    return OrbitMeanElementsMessage(v"3.0", header, body)
end

function OrbitMeanElementsMessage(omm::OrbitMeanElementsMessage; kwargs...)
    return OrbitMeanElementsMessage(
        ;
        # == Header ========================================================================

        header_comment = omm.header.comment,
        classification = omm.header.classification,
        creation_date  = omm.header.creation_date,
        originator     = omm.header.originator,
        message_id     = omm.header.message_id,

        # == Metadata ======================================================================

        metadata_comment    = omm.body.segment.metadata.comment,
        object_name         = omm.body.segment.metadata.object_name,
        object_id           = omm.body.segment.metadata.object_id,
        center_name         = omm.body.segment.metadata.center_name,
        ref_frame           = omm.body.segment.metadata.ref_frame,
        ref_frame_epoch     = omm.body.segment.metadata.ref_frame_epoch,
        time_system         = omm.body.segment.metadata.time_system,
        mean_element_theory = omm.body.segment.metadata.mean_element_theory,

        # == Data ==========================================================================

        # -- Mean Keplerian Elements -------------------------------------------------------

        data_comment      = omm.body.segment.data.data_comment,
        epoch             = omm.body.segment.data.epoch,
        semi_major_axis   = omm.body.segment.data.semi_major_axis,
        mean_motion       = omm.body.segment.data.mean_motion,
        eccentricity      = omm.body.segment.data.eccentricity,
        inclination       = omm.body.segment.data.inclination,
        raan              = omm.body.segment.data.raan,
        arg_of_pericenter = omm.body.segment.data.arg_of_pericenter,
        mean_anomaly      = omm.body.segment.data.mean_anomaly,
        GM                = omm.body.segment.data.GM,

        # -- Spacecraft Data ---------------------------------------------------------------

        spacecraft_data_comment = omm.body.segment.data.spacecraft_data_comment,
        mass                    = omm.body.segment.data.mass,
        solar_rad_area          = omm.body.segment.data.solar_rad_area,
        solar_rad_coeff         = omm.body.segment.data.solar_rad_coeff,
        drag_area               = omm.body.segment.data.drag_area,
        drag_coeff              = omm.body.segment.data.drag_coeff,

        # -- TLE Related Parameters ------------------------------------------------------------

        tle_parameters_comment = omm.body.segment.data.tle_parameters_comment,
        ephemeris_type         = omm.body.segment.data.ephemeris_type,
        classification_type    = omm.body.segment.data.classification_type,
        norad_cat_id           = omm.body.segment.data.norad_cat_id,
        element_set_number     = omm.body.segment.data.element_set_number,
        rev_at_epoch           = omm.body.segment.data.rev_at_epoch,
        bstar                  = omm.body.segment.data.bstar,
        mean_motion_dot        = omm.body.segment.data.mean_motion_dot,
        mean_motion_ddot       = omm.body.segment.data.mean_motion_ddot,

        # -- User-Defined Parameters ------------------------------------------------------------

        user_defined_parameters = omm.body.segment.data.user_defined_parameters,

        kwargs...
    )
end

# == Fetchers ==============================================================================

abstract type AbstractOmmFetcher end
