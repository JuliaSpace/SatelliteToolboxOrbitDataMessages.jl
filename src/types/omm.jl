## Description #############################################################################
#
# Definition of types and constructors for Orbit Mean-Elements Messages (OMM).
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

@kwdef struct OmmData{T<:AbstractFloat}
    # == Mean Keplerian Elements ===========================================================

    data_comment::Union{String, Nothing} = nothing
    epoch::NanoDate
    semi_major_axis::Union{T, Nothing} = nothing
    mean_motion::Union{T, Nothing} = nothing
    eccentricity::T
    inclination::T
    raan::T
    arg_of_pericenter::T
    mean_anomaly::T
    GM::Union{T, Nothing} = nothing

    # == Spacecraft Data ===================================================================

    spacecraft_data_comment::Union{String, Nothing} = nothing
    mass::Union{T, Nothing} = nothing
    solar_rad_area::Union{T, Nothing} = nothing
    solar_rad_coeff::Union{T, Nothing} = nothing
    drag_area::Union{T, Nothing} = nothing
    drag_coeff::Union{T, Nothing} = nothing

    # == TLE Related Parameters ============================================================

    tle_parameters_comment::Union{String, Nothing} = nothing
    ephemeris_type::Union{Int, Nothing} = nothing
    classification_type::Union{Char, Nothing} = nothing
    norad_cat_id::Union{Int, Nothing} = nothing
    element_set_number::Union{Int, Nothing} = nothing
    rev_at_epoch::Union{Int, Nothing} = nothing
    bstar::Union{T, Nothing} = nothing
    mean_motion_dot::Union{T, Nothing} = nothing
    mean_motion_ddot::Union{T, Nothing} = nothing

    # == Covariance Matrix =================================================================

    # TODO: Support covariance matrix.

    # == User-Defined Parameters ===========================================================

    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}} = nothing
end

# -- Segment -------------------------------------------------------------------------------

@kwdef struct OmmSegment{T<:AbstractFloat}
    metadata::OmmMetadata
    data::OmmData{T}
end

# -- Body ----------------------------------------------------------------------------------

@kwdef struct OmmBody{T<:AbstractFloat}
    segment::OmmSegment
end

# -- OMM -----------------------------------------------------------------------------------

struct OrbitMeanElementsMessage{T<:AbstractFloat} <: OrbitDataMessage{T}
    version::VersionNumber
    header::OmmHeader
    body::OmmBody{T}
end

# == Constructors ==========================================================================

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
    semi_major_axis::Union{T, Nothing} = nothing,
    mean_motion::Union{T, Nothing} = nothing,
    eccentricity::T,
    inclination::T,
    raan::T,
    arg_of_pericenter::T,
    mean_anomaly::T,
    GM::Union{T, Nothing} = nothing,

    # -- Spacecraft Data -------------------------------------------------------------------

    spacecraft_data_comment::Union{String, Nothing} = nothing,
    mass::Union{T, Nothing} = nothing,
    solar_rad_area::Union{T, Nothing} = nothing,
    solar_rad_coeff::Union{T, Nothing} = nothing,
    drag_area::Union{T, Nothing} = nothing,
    drag_coeff::Union{T, Nothing} = nothing,

    # -- TLE Related Parameters ------------------------------------------------------------

    tle_parameters_comment::Union{String, Nothing} = nothing,
    ephemeris_type::Union{Int, Nothing} = nothing,
    classification_type::Union{Char, Nothing} = nothing,
    norad_cat_id::Union{Int, Nothing} = nothing,
    element_set_number::Union{Int, Nothing} = nothing,
    rev_at_epoch::Union{Int, Nothing} = nothing,
    bstar::Union{T, Nothing} = nothing,
    mean_motion_dot::Union{T, Nothing} = nothing,
    mean_motion_ddot::Union{T, Nothing} = nothing,

    # -- User-Defined Parameters -----------------------------------------------------------

    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}} = nothing
) where T <: AbstractFloat
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

    data = OmmData{T}(
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

    segment = OmmSegment{T}(metadata, data)

    body = OmmBody{T}(segment)

    return OrbitMeanElementsMessage{T}(v"3.0", header, body)
end

function OrbitMeanElementsMessage(
    omm::OrbitMeanElementsMessage{T};
    kwargs...
) where T <: AbstractFloat
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

        # -- User-Defined Parameters -----------------------------------------------------------

        user_defined_parameters = omm.body.segment.data.user_defined_parameters,

        kwargs...
    )
end

# == Fetchers ==============================================================================

abstract type AbstractOmmFetcher end

