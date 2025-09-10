## Description #############################################################################
#
# Definition of types and structures.
#
############################################################################################

export OrbitMeanElementsMessage

abstract type OrbitDataMessage{T<:AbstractFloat} end

# == Orbit Mean-Elements Message (OMM) =====================================================

struct OmmHeader
    comment::Union{String, Nothing}
    classification::Union{String, Nothing}
    creation_date::NanoDate
    originator::String
    message_id::Union{String, Nothing}
end

struct OmmMetadata
    comment::Union{String, Nothing}
    object_name::String
    object_id::String
    center_name::String
    ref_frame::String
    ref_frame_epoch::Union{NanoDate, Nothing}
    time_system::String
    mean_element_theory::String
end

struct OmmData{T<:AbstractFloat}
    # == Mean Keplerian Elements ===========================================================

    data_comment::Union{String, Nothing}
    epoch::NanoDate
    semi_major_axis::Union{T, Nothing}
    mean_motion::Union{T, Nothing}
    eccentricity::T
    inclination::T
    raan::T
    arg_of_pericenter::T
    mean_anomaly::T
    GM::Union{T, Nothing}

    # == Spacecraft Data ===================================================================

    spacecraft_data_comment::Union{String, Nothing}
    mass::Union{T, Nothing}
    solar_rad_area::Union{T, Nothing}
    solar_rad_coeff::Union{T, Nothing}
    drag_area::Union{T, Nothing}
    drag_coeff::Union{T, Nothing}

    # == TLE Related Parameters ============================================================

    tle_parameters_comment::Union{String, Nothing}
    ephemeris_type::Union{Int, Nothing}
    classification_type::Union{Char, Nothing}
    norad_cat_id::Union{Int, Nothing}
    element_set_number::Union{Int, Nothing}
    rev_at_epoch::Union{Int, Nothing}
    bstar::Union{T, Nothing}
    mean_motion_dot::Union{T, Nothing}
    mean_motion_ddot::Union{T, Nothing}

    # -- Covariance Matrix -----------------------------------------------------------------

    # TODO: Support covariance matrix.

    # -- User-Defined Parameters -----------------------------------------------------------

    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}}
end

struct OmmSegment{T<:AbstractFloat}
    metadata::OmmMetadata
    data::OmmData{T}
end

struct OmmBody{T<:AbstractFloat}
    segment::OmmSegment
end

struct OrbitMeanElementsMessage{T<:AbstractFloat} <: OrbitDataMessage{T}
    version::VersionNumber
    header::OmmHeader
    body::OmmBody{T}
end

# == Fetchers ==============================================================================

abstract type AbstractOmmFetcher end
