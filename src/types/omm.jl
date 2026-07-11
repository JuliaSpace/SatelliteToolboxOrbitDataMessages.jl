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

export OrbitMeanElementsMessage, OmmCovarianceMatrix

# == Types =================================================================================

# -- Header --------------------------------------------------------------------------------

@kwdef struct OmmHeader
    comments::Vector{String} = String[]
    classification::Union{String, Nothing} = nothing
    creation_date::Union{NanoDate, Nothing}
    originator::String
    message_id::Union{String, Nothing} = nothing
end

# -- Metadata ------------------------------------------------------------------------------

@kwdef struct OmmMetadata
    comments::Vector{String} = String[]
    object_name::String
    object_id::String
    center_name::String
    ref_frame::String
    ref_frame_epoch::Union{NanoDate, Nothing} = nothing
    time_system::String
    mean_element_theory::String
end

# -- Data ----------------------------------------------------------------------------------

"""
    struct OmmCovarianceMatrix

Covariance matrix of an Orbit Mean-Elements Message (OMM) as defined by the CCSDS 502.0-B-3
standard.

The matrix is symmetric, so only the upper-triangular 21 elements are stored. The elements
follow the CCSDS naming convention where `CX_X` is the (1,1) entry, `CY_X` is the (2,1)
entry, etc.

# Fields

- `comments::Vector{String}`: Comments for the covariance matrix section.
- `cov_ref_frame::Union{String, Nothing}`: Reference frame of the covariance matrix.
- `cx_x::Float64`: (1,1) element [km²].
- `cy_x::Float64`: (2,1) element [km²].
- `cy_y::Float64`: (2,2) element [km²].
- `cz_x::Float64`: (3,1) element [km²].
- `cz_y::Float64`: (3,2) element [km²].
- `cz_z::Float64`: (3,3) element [km²].
- `cx_dot_x::Float64`: (4,1) element [km²/s].
- `cx_dot_y::Float64`: (4,2) element [km²/s].
- `cx_dot_z::Float64`: (4,3) element [km²/s].
- `cx_dot_x_dot::Float64`: (4,4) element [km²/s²].
- `cy_dot_x::Float64`: (5,1) element [km²/s].
- `cy_dot_y::Float64`: (5,2) element [km²/s].
- `cy_dot_z::Float64`: (5,3) element [km²/s].
- `cy_dot_x_dot::Float64`: (5,4) element [km²/s²].
- `cy_dot_y_dot::Float64`: (5,5) element [km²/s²].
- `cz_dot_x::Float64`: (6,1) element [km²/s].
- `cz_dot_y::Float64`: (6,2) element [km²/s].
- `cz_dot_z::Float64`: (6,3) element [km²/s].
- `cz_dot_x_dot::Float64`: (6,4) element [km²/s²].
- `cz_dot_y_dot::Float64`: (6,5) element [km²/s²].
- `cz_dot_z_dot::Float64`: (6,6) element [km²/s²].
"""
@kwdef struct OmmCovarianceMatrix
    comments::Vector{String} = String[]
    cov_ref_frame::Union{String, Nothing} = nothing
    cx_x::Float64
    cy_x::Float64
    cy_y::Float64
    cz_x::Float64
    cz_y::Float64
    cz_z::Float64
    cx_dot_x::Float64
    cx_dot_y::Float64
    cx_dot_z::Float64
    cx_dot_x_dot::Float64
    cy_dot_x::Float64
    cy_dot_y::Float64
    cy_dot_z::Float64
    cy_dot_x_dot::Float64
    cy_dot_y_dot::Float64
    cz_dot_x::Float64
    cz_dot_y::Float64
    cz_dot_z::Float64
    cz_dot_x_dot::Float64
    cz_dot_y_dot::Float64
    cz_dot_z_dot::Float64
end

@kwdef struct OmmData
    # == Mean Keplerian Elements ===========================================================

    comments::Vector{String} = String[]
    mean_elements_comments::Vector{String} = String[]
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

    spacecraft_parameters_comments::Vector{String} = String[]
    mass::Union{Float64, Nothing} = nothing
    solar_rad_area::Union{Float64, Nothing} = nothing
    solar_rad_coeff::Union{Float64, Nothing} = nothing
    drag_area::Union{Float64, Nothing} = nothing
    drag_coeff::Union{Float64, Nothing} = nothing

    # == TLE Related Parameters ===========================================================

    tle_parameters_comments::Vector{String} = String[]
    ephemeris_type::Union{Int, Nothing} = nothing
    classification_type::Union{Char, Nothing} = nothing
    norad_cat_id::Union{Int, Nothing} = nothing
    element_set_number::Union{Int, Nothing} = nothing
    rev_at_epoch::Union{Int, Nothing} = nothing
    bstar::Union{Float64, Nothing} = nothing
    bterm::Union{Float64, Nothing} = nothing
    mean_motion_dot::Union{Float64, Nothing} = nothing
    mean_motion_ddot::Union{Float64, Nothing} = nothing
    agom::Union{Float64, Nothing} = nothing

    # == Covariance Matrix =================================================================

    covariance_matrix::Union{OmmCovarianceMatrix, Nothing} = nothing

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

# == Equality and Hashing ==================================================================

# Define `==` and `hash` by comparing and hashing all fields. Both functions are generated
# together to keep the invariant `x == y` ⟹ `hash(x) == hash(y)`, which is required for
# the types to behave correctly in `Dict`s and `Set`s.
for T in (
    :OmmHeader,
    :OmmMetadata,
    :OmmCovarianceMatrix,
    :OmmData,
    :OmmSegment,
    :OmmBody,
    :OrbitMeanElementsMessage,
)
    @eval begin
        function ==(x::$T, y::$T)
            return all(f -> getfield(x, f) == getfield(y, f), fieldnames($T))
        end

        function Base.hash(x::$T, h::UInt)
            h = hash($(QuoteNode(T)), h)

            for f in fieldnames($T)
                h = hash(getfield(x, f), h)
            end

            return h
        end
    end
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

- `header_comments::Vector{String}`: Comments for the header section.
    (**Default**: `String[]`)
- `classification::Union{String, Nothing}`: Message classification.
    (**Default**: `nothing`)
- `creation_date::NanoDate`: Message creation date (**required**).
- `originator::String`: Message originator (**required**).
- `message_id::Union{String, Nothing}`: Unique message identifier.
    (**Default**: `nothing`)
- `metadata_comments::Vector{String}`: Comments for the metadata section.
    (**Default**: `String[]`)
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
- `data_comments::Vector{String}`: Comments for the data section.
    (**Default**: `String[]`)
- `mean_elements_comments::Vector{String}`: Comments for the mean elements section.
    (**Default**: `String[]`)
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
- `spacecraft_parameters_comments::Vector{String}`: Comments for the spacecraft parameters
    section.
    (**Default**: `String[]`)
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
- `tle_parameters_comments::Vector{String}`: Comments for the TLE-related parameters
    section.
    (**Default**: `String[]`)
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
- `bterm::Union{Float64, Nothing}`: Ballistic coefficient [m²/kg].
    (**Default**: `nothing`)
- `mean_motion_dot::Union{Float64, Nothing}`: First time derivative of the mean motion
    [rev/day²].
    (**Default**: `nothing`)
- `mean_motion_ddot::Union{Float64, Nothing}`: Second time derivative of the mean motion
    [rev/day³].
    (**Default**: `nothing`)
- `agom::Union{Float64, Nothing}`: Solar radiation pressure coefficient [m²/kg].
    (**Default**: `nothing`)
- `user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}}`: User-defined
    parameters as a vector of `key => value` pairs.
    (**Default**: `nothing`)

    OrbitMeanElementsMessage(
        omm::OrbitMeanElementsMessage;
        kwargs...
    ) -> OrbitMeanElementsMessage

Create a copy of `omm`, overriding the fields specified in `kwargs...`. Any keyword accepted
by the main constructor can be used; the remaining fields are copied from `omm`.
"""
function OrbitMeanElementsMessage(
    ;
    # == Header ============================================================================
    header_comments::Vector{String} = String[],
    classification::Union{String, Nothing} = nothing,
    creation_date::NanoDate,
    originator::String,
    message_id::Union{String, Nothing} = nothing,

    # == Metadata ==========================================================================
    metadata_comments::Vector{String} = String[],
    object_name::String,
    object_id::String,
    center_name::String,
    ref_frame::String,
    ref_frame_epoch::Union{NanoDate, Nothing} = nothing,
    time_system::String,
    mean_element_theory::String,

    # == Data =============================================================================

    # -- Mean Keplerian Elements -----------------------------------------------------------

    data_comments::Vector{String} = String[],
    mean_elements_comments::Vector{String} = String[],
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

    spacecraft_parameters_comments::Vector{String} = String[],
    mass::Union{Float64, Nothing} = nothing,
    solar_rad_area::Union{Float64, Nothing} = nothing,
    solar_rad_coeff::Union{Float64, Nothing} = nothing,
    drag_area::Union{Float64, Nothing} = nothing,
    drag_coeff::Union{Float64, Nothing} = nothing,

    # -- TLE Related Parameters ------------------------------------------------------------

    tle_parameters_comments::Vector{String} = String[],
    ephemeris_type::Union{Int, Nothing} = nothing,
    classification_type::Union{Char, Nothing} = nothing,
    norad_cat_id::Union{Int, Nothing} = nothing,
    element_set_number::Union{Int, Nothing} = nothing,
    rev_at_epoch::Union{Int, Nothing} = nothing,
    bstar::Union{Float64, Nothing} = nothing,
    bterm::Union{Float64, Nothing} = nothing,
    mean_motion_dot::Union{Float64, Nothing} = nothing,
    mean_motion_ddot::Union{Float64, Nothing} = nothing,
    agom::Union{Float64, Nothing} = nothing,

    # -- Covariance Matrix ----------------------------------------------------------------

    covariance_matrix::Union{OmmCovarianceMatrix, Nothing} = nothing,

    # -- User-Defined Parameters -----------------------------------------------------------

    user_defined_parameters::Union{Nothing, Vector{Pair{String, String}}} = nothing
)
    (isnothing(semi_major_axis) == isnothing(mean_motion)) && throw(ArgumentError(
        "Exactly one of `semi_major_axis` and `mean_motion` must be provided."
    ))

    has_tle_parameters =
        !isempty(tle_parameters_comments) ||
        any(!isnothing, (
            ephemeris_type,
            classification_type,
            norad_cat_id,
            element_set_number,
            rev_at_epoch,
            bstar,
            bterm,
            mean_motion_dot,
            mean_motion_ddot,
            agom,
        ))

    if has_tle_parameters
        (isnothing(bstar) == isnothing(bterm)) && throw(ArgumentError(
            "Exactly one of `bstar` and `bterm` is required in TLE parameters."
        ))
        isnothing(mean_motion_dot) && throw(ArgumentError(
            "`mean_motion_dot` is required in TLE parameters."
        ))
        (isnothing(mean_motion_ddot) == isnothing(agom)) && throw(ArgumentError(
            "Exactly one of `mean_motion_ddot` and `agom` is required in TLE parameters."
        ))
    end

    header = OmmHeader(
        ;
        comments = copy(header_comments),
        classification,
        creation_date,
        originator,
        message_id,
    )

    metadata = OmmMetadata(
        ;
        comments = copy(metadata_comments),
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
        comments = copy(data_comments),
        mean_elements_comments = copy(mean_elements_comments),
        epoch,
        semi_major_axis,
        mean_motion,
        eccentricity,
        inclination,
        raan,
        arg_of_pericenter,
        mean_anomaly,
        GM,
        spacecraft_parameters_comments = copy(spacecraft_parameters_comments),
        mass,
        solar_rad_area,
        solar_rad_coeff,
        drag_area,
        drag_coeff,
        tle_parameters_comments = copy(tle_parameters_comments),
        ephemeris_type,
        classification_type,
        norad_cat_id,
        element_set_number,
        rev_at_epoch,
        bstar,
        bterm,
        mean_motion_dot,
        mean_motion_ddot,
        agom,
        covariance_matrix,
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

        header_comments = omm.header.comments,
        classification = omm.header.classification,
        creation_date  = omm.header.creation_date,
        originator     = omm.header.originator,
        message_id     = omm.header.message_id,

        # == Metadata ======================================================================

        metadata_comments   = omm.body.segment.metadata.comments,
        object_name         = omm.body.segment.metadata.object_name,
        object_id           = omm.body.segment.metadata.object_id,
        center_name         = omm.body.segment.metadata.center_name,
        ref_frame           = omm.body.segment.metadata.ref_frame,
        ref_frame_epoch     = omm.body.segment.metadata.ref_frame_epoch,
        time_system         = omm.body.segment.metadata.time_system,
        mean_element_theory = omm.body.segment.metadata.mean_element_theory,

        # == Data ==========================================================================

        # -- Mean Keplerian Elements -------------------------------------------------------

        data_comments          = omm.body.segment.data.comments,
        mean_elements_comments = omm.body.segment.data.mean_elements_comments,
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

        spacecraft_parameters_comments =
            omm.body.segment.data.spacecraft_parameters_comments,
        mass                    = omm.body.segment.data.mass,
        solar_rad_area          = omm.body.segment.data.solar_rad_area,
        solar_rad_coeff         = omm.body.segment.data.solar_rad_coeff,
        drag_area               = omm.body.segment.data.drag_area,
        drag_coeff              = omm.body.segment.data.drag_coeff,

        # -- TLE Related Parameters --------------------------------------------------------

        tle_parameters_comments = omm.body.segment.data.tle_parameters_comments,
        ephemeris_type         = omm.body.segment.data.ephemeris_type,
        classification_type    = omm.body.segment.data.classification_type,
        norad_cat_id           = omm.body.segment.data.norad_cat_id,
        element_set_number     = omm.body.segment.data.element_set_number,
        rev_at_epoch           = omm.body.segment.data.rev_at_epoch,
        bstar                  = omm.body.segment.data.bstar,
        bterm                  = omm.body.segment.data.bterm,
        mean_motion_dot        = omm.body.segment.data.mean_motion_dot,
        mean_motion_ddot       = omm.body.segment.data.mean_motion_ddot,
        agom                   = omm.body.segment.data.agom,

        # -- Covariance Matrix -------------------------------------------------------------

        covariance_matrix      = omm.body.segment.data.covariance_matrix,

        # -- User-Defined Parameters -------------------------------------------------------

        user_defined_parameters = omm.body.segment.data.user_defined_parameters,

        kwargs...
    )
end

# == Fetchers ==============================================================================

abstract type AbstractOmmFetcher end
