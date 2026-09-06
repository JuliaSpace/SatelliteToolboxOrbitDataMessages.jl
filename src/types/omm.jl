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

export OrbitMeanElementsMessage, OMM
export OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix

# == Types =================================================================================

# -- Header --------------------------------------------------------------------------------

"""
    struct OmmHeader

Header section of an Orbit Mean-Elements Message (OMM) as defined by the CCSDS 502.0-B-3
standard. Create it with the keyword constructor `OmmHeader(; kwargs...)`, whose keywords
are the fields below.

# Fields

- `comments::Vector{String}`: Comments for the header section.
    (**Default**: `String[]`)
- `classification::Union{String, Nothing}`: Message classification.
    (**Default**: `nothing`)
- `creation_date::Union{NanoDate, Nothing}`: Message creation date. It can only be
    `nothing` for parsed messages whose input omits it, which cannot be written until a
    creation date is set.
    (**Default**: `nothing`)
- `originator::String`: Message originator.
- `message_id::Union{String, Nothing}`: Unique message identifier.
    (**Default**: `nothing`)
"""
@kwdef struct OmmHeader
    comments::Vector{String} = String[]
    classification::Union{String, Nothing} = nothing
    creation_date::Union{NanoDate, Nothing} = nothing
    originator::String
    message_id::Union{String, Nothing} = nothing
end

# -- Metadata ------------------------------------------------------------------------------

"""
    struct OmmMetadata

Metadata section of an Orbit Mean-Elements Message (OMM) as defined by the CCSDS 502.0-B-3
standard. Create it with the keyword constructor `OmmMetadata(; kwargs...)`, whose
keywords are the fields below.

# Fields

- `comments::Vector{String}`: Comments for the metadata section.
    (**Default**: `String[]`)
- `object_name::String`: Spacecraft name.
- `object_id::String`: International designator, usually in the format `YYYY-NNNP`.
- `center_name::String`: Origin of the reference frame.
- `ref_frame::String`: Reference frame of the mean elements.
- `ref_frame_epoch::Union{NanoDate, Nothing}`: Epoch of the reference frame, if it is not
    intrinsic to its definition.
    (**Default**: `nothing`)
- `time_system::String`: Time system used for the message.
- `mean_element_theory::String`: Theory describing the mean elements, e.g. `"SGP4"`.
"""
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

The matrix is symmetric, so only the lower-triangular 21 elements are stored. The elements
follow the CCSDS naming convention where `CX_X` is the (1,1) entry, `CY_X` is the (2,1)
entry, etc. Create it with the keyword constructor `OmmCovarianceMatrix(; kwargs...)`,
whose keywords are the fields below.

# Fields

- `comments::Vector{String}`: Comments for the covariance matrix section.
    (**Default**: `String[]`)
- `cov_ref_frame::Union{String, Nothing}`: Reference frame of the covariance matrix.
    (**Default**: `nothing`)
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

"""
    struct OmmData

Data section of an Orbit Mean-Elements Message (OMM) as defined by the CCSDS 502.0-B-3
standard, containing the mean Keplerian elements and the optional spacecraft parameters,
TLE-related parameters, covariance matrix, and user-defined parameters. Create it with the
keyword constructor `OmmData(; kwargs...)`, whose keywords are the fields below. The rules
relating the fields (e.g. exactly one of `semi_major_axis` and `mean_motion`) are checked
when the section is assembled into an [`OrbitMeanElementsMessage`](@ref).

# Fields

- `comments::Vector{String}`: Comments for the data section.
    (**Default**: `String[]`)
- `mean_elements_comments::Vector{String}`: Comments for the mean elements section.
    (**Default**: `String[]`)
- `epoch::NanoDate`: Epoch of the mean Keplerian elements.
- `semi_major_axis::Union{Float64, Nothing}`: Semi-major axis [km].
    (**Default**: `nothing`)
- `mean_motion::Union{Float64, Nothing}`: Mean motion [rev/day].
    (**Default**: `nothing`)
- `eccentricity::Float64`: Eccentricity.
- `inclination::Float64`: Inclination [deg].
- `raan::Float64`: Right ascension of the ascending node [deg].
- `arg_of_pericenter::Float64`: Argument of pericenter [deg].
- `mean_anomaly::Float64`: Mean anomaly [deg].
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
- `bstar::Union{Float64, Nothing}`: SGP4 drag term (B*) [1/ER].
    (**Default**: `nothing`)
- `bterm::Union{Float64, Nothing}`: Ballistic coefficient [m²/kg].
    (**Default**: `nothing`)
- `mean_motion_dot::Union{Float64, Nothing}`: First time derivative of the mean motion
    [rev/day²].
    (**Default**: `nothing`)
- `mean_motion_ddot::Union{Float64, Nothing}`: Second time derivative of the mean motion
    [rev/day³].
    (**Default**: `nothing`)
- `agom::Union{Float64, Nothing}`: Solar radiation pressure coefficient AGOM [m²/kg].
    (**Default**: `nothing`)
- `covariance_matrix::Union{OmmCovarianceMatrix, Nothing}`: Covariance matrix of the
    message.
    (**Default**: `nothing`)
- `user_defined_parameters::Vector{Pair{String, String}}`: User-defined parameters as a
    vector of `key => value` pairs. An empty vector means that the section is absent.
    (**Default**: `Pair{String, String}[]`)
"""
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

    # == TLE Related Parameters ============================================================

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

    user_defined_parameters::Vector{Pair{String, String}} = Pair{String, String}[]
end

# -- OMM -----------------------------------------------------------------------------------

"""
    struct OrbitMeanElementsMessage <: OrbitDataMessage

Orbit Mean-Elements Message (OMM) as defined by the CCSDS 502.0-B-3 standard.

The structure contains the three sections defined by the standard: a `header`, a
`metadata`, and a `data` section. The individual fields can be accessed through these
sections, for example `omm.metadata.object_name` or `omm.data.epoch`, or directly as
properties of the message, for example `omm.object_name` or `omm.epoch` (see the extended
help).

To create a message, use the flat keyword constructor
`OrbitMeanElementsMessage(; kwargs...)`, which assembles all the internal sections
automatically, or build the sections with
[`OmmHeader`](@ref), [`OmmMetadata`](@ref), and [`OmmData`](@ref) and pass them to
`OrbitMeanElementsMessage(header, metadata, data; version)`. Every constructor checks the
rules relating the fields, throwing an `ArgumentError` if they are violated. The alias
[`OMM`](@ref) can be used instead of the full name.

# Fields

- `version::VersionNumber`: OMM format version (2.0 or 3.0).
- `header::OmmHeader`: Message header (creation date, originator, etc.).
- `metadata::OmmMetadata`: Message metadata (object identification, reference frame, etc.).
- `data::OmmData`: Mean elements data (mean Keplerian elements, TLE parameters, etc.).

# Extended help

## Properties

Every field of the header, metadata, and data sections is also available as a property of
the message with the same name, so `omm.epoch` is equivalent to `omm.data.epoch`. The only
exception is the `comments` field, which exists in every section and must be accessed
through the section, e.g. `omm.header.comments`. The complete list is returned by
`propertynames(omm)`.
"""
struct OrbitMeanElementsMessage <: OrbitDataMessage
    version::VersionNumber
    header::OmmHeader
    metadata::OmmMetadata
    data::OmmData

    function OrbitMeanElementsMessage(
        version::VersionNumber, header::OmmHeader, metadata::OmmMetadata, data::OmmData
    )
        _omm_check_rules(version, data)
        return new(version, header, metadata, data)
    end
end

"""
    const OMM = OrbitMeanElementsMessage

Short alias of [`OrbitMeanElementsMessage`](@ref).
"""
const OMM = OrbitMeanElementsMessage

# == Equality and Hashing ==================================================================

# Define `==`, `isequal`, and `hash` by comparing and hashing all fields. The three
# functions are generated together to keep the invariant `isequal(x, y)` ⟹
# `hash(x) == hash(y)`, which is required for the types to behave correctly in `Dict`s and
# `Set`s. `isequal` cannot be derived from the generated `==` because the two differ for
# floating-point fields (`-0.0` vs. `0.0` and `NaN`), whereas `hash` follows the `isequal`
# semantics. The field accesses are unrolled at code-generation time, yielding type-stable
# and allocation-free implementations.
for T in (OmmHeader, OmmMetadata, OmmCovarianceMatrix, OmmData, OrbitMeanElementsMessage)
    name = nameof(T)

    eq_expr = foldr(
        (f, acc) ->
            :((getfield(x, $(QuoteNode(f))) == getfield(y, $(QuoteNode(f)))) && $acc),
        fieldnames(T);
        init = true,
    )

    isequal_expr = foldr(
        (f, acc) ->
            :(isequal(getfield(x, $(QuoteNode(f))), getfield(y, $(QuoteNode(f)))) && $acc),
        fieldnames(T);
        init = true,
    )

    hash_exprs = [:(h = hash(getfield(x, $(QuoteNode(f))), h)) for f in fieldnames(T)]

    @eval begin
        ==(x::$name, y::$name) = $eq_expr

        Base.isequal(x::$name, y::$name) = $isequal_expr

        function Base.hash(x::$name, h::UInt)
            h = hash($(QuoteNode(name)), h)
            $(hash_exprs...)
            return h
        end
    end
end

# == Constructors ==========================================================================

"""
    OrbitMeanElementsMessage(; kwargs...) -> OrbitMeanElementsMessage

Create an Orbit Mean-Elements Message (OMM) from the keyword arguments `kwargs...`.

This constructor assembles the internal header, metadata, and data sections defined by the
CCSDS 502.0-B-3 standard, returning a message with version 3.0 unless `version` is
provided. The required keywords are the message creation date, the originator, the object
identification, the reference frame and time system, and the mean Keplerian elements. All
angular quantities (`inclination`, `raan`, `arg_of_pericenter`, and `mean_anomaly`) are
expressed in **degrees**. An `ArgumentError` is thrown if the keyword combination violates
the message rules (see the extended help). The sections can also be built individually
and assembled with `OrbitMeanElementsMessage(header, metadata, data; version)`.

The date keywords (`creation_date`, `epoch`, and `ref_frame_epoch`) must be provided as
`NanoDate` objects so that the sub-second precision is preserved.

# Keywords

- `version::VersionNumber`: OMM format version (`v"2.0"` or `v"3.0"`). The
    version-specific field rules are enforced by the parsers, and the writers always emit
    version 3.0.
    (**Default**: `v"3.0"`)
- `header_comments::Vector{String}`: Comments for the header section.
    (**Default**: `String[]`)
- `classification::Union{String, Nothing}`: Message classification.
    (**Default**: `nothing`)
- `creation_date::Union{NanoDate, Nothing}`: Message creation date (**required**). It can
    only be `nothing` for parsed messages whose input omits it (see [`parse_omm`](@ref)),
    which cannot be written until a creation date is set.
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
- `bstar::Union{Float64, Nothing}`: SGP4 drag term (B*) [1/ER].
    (**Default**: `nothing`)
- `bterm::Union{Float64, Nothing}`: Ballistic coefficient [m²/kg].
    (**Default**: `nothing`)
- `mean_motion_dot::Union{Float64, Nothing}`: First time derivative of the mean motion
    [rev/day²].
    (**Default**: `nothing`)
- `mean_motion_ddot::Union{Float64, Nothing}`: Second time derivative of the mean motion
    [rev/day³].
    (**Default**: `nothing`)
- `agom::Union{Float64, Nothing}`: Solar radiation pressure coefficient AGOM [m²/kg].
    (**Default**: `nothing`)
- `covariance_matrix::Union{OmmCovarianceMatrix, Nothing}`: Covariance matrix of the
    message.
    (**Default**: `nothing`)
- `user_defined_parameters::Vector{Pair{String, String}}`: User-defined parameters as a
    vector of `key => value` pairs. An empty vector means that the section is absent.
    (**Default**: `Pair{String, String}[]`)

# Extended help

## Throws

- `ArgumentError`: If `version` is not `v"2.0"` or `v"3.0"`.
- `ArgumentError`: If not exactly one of `semi_major_axis` and `mean_motion` is provided.
- `ArgumentError`: If the TLE-related parameters section is present (any of its keywords
    or comments is set) and not exactly one of `bstar` and `bterm` is provided, or
    `mean_motion_dot` is missing, or not exactly one of `mean_motion_ddot` and `agom` is
    provided.
"""
function OrbitMeanElementsMessage(;
    # == Version ===========================================================================
    version::VersionNumber = v"3.0",

    # == Header ============================================================================
    header_comments::Vector{String} = String[],
    classification::Union{String, Nothing} = nothing,
    creation_date::Union{NanoDate, Nothing},
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

    # == Data ==============================================================================

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

    # -- Covariance Matrix -----------------------------------------------------------------

    covariance_matrix::Union{OmmCovarianceMatrix, Nothing} = nothing,

    # -- User-Defined Parameters -----------------------------------------------------------

    user_defined_parameters::Vector{Pair{String, String}} = Pair{String, String}[],
)
    header = OmmHeader(;
        comments = copy(header_comments),
        classification,
        creation_date,
        originator,
        message_id,
    )

    metadata = OmmMetadata(;
        comments = copy(metadata_comments),
        object_name,
        object_id,
        center_name,
        ref_frame,
        ref_frame_epoch,
        time_system,
        mean_element_theory,
    )

    data = OmmData(;
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
        user_defined_parameters = copy(user_defined_parameters),
    )

    return OrbitMeanElementsMessage(version, header, metadata, data)
end

"""
    OrbitMeanElementsMessage(
        header::OmmHeader,
        metadata::OmmMetadata,
        data::OmmData;
        version::VersionNumber = v"3.0"
    ) -> OrbitMeanElementsMessage

Create an Orbit Mean-Elements Message (OMM) with `version` from its `header`, `metadata`,
and `data` sections. An `ArgumentError` is thrown if `version` is not `v"2.0"` or `v"3.0"`
or the data section violates the message rules (see the extended help of the keyword
constructor).
"""
function OrbitMeanElementsMessage(
    header::OmmHeader, metadata::OmmMetadata, data::OmmData; version::VersionNumber = v"3.0"
)
    return OrbitMeanElementsMessage(version, header, metadata, data)
end

"""
    OrbitMeanElementsMessage(
        omm::OrbitMeanElementsMessage;
        kwargs...
    ) -> OrbitMeanElementsMessage

Create a copy of `omm`, overriding the fields specified in `kwargs...`. Any keyword
accepted by the keyword constructor can be used; the remaining fields, including the
message version, are copied from `omm`.
"""
function OrbitMeanElementsMessage(omm::OrbitMeanElementsMessage; kwargs...)
    return OrbitMeanElementsMessage(; _omm_keywords(omm)..., kwargs...)
end

# Generate `_omm_keywords`, which converts a message to the keywords of the flat keyword
# constructor. The section fields keep their names, except the comments, which are
# prefixed by the section name.
let keywords = Expr[:(version = omm.version)]
    for (section, T, comments) in (
        (:header, OmmHeader, :header_comments),
        (:metadata, OmmMetadata, :metadata_comments),
        (:data, OmmData, :data_comments),
    )
        for field in fieldnames(T)
            keyword = field === :comments ? comments : field
            push!(keywords, :($keyword = omm.$section.$field))
        end
    end

    @eval begin
        """
            _omm_keywords(omm::OrbitMeanElementsMessage) -> NamedTuple

        Return the keywords of the flat keyword constructor that reproduce `omm`.
        """
        _omm_keywords(omm::OrbitMeanElementsMessage) = (; $(keywords...))
    end
end

# Generate the copy constructors of the sections, which mirror the one of the message.
for T in (OmmHeader, OmmMetadata, OmmCovarianceMatrix, OmmData)
    name     = nameof(T)
    keywords = [:($field = section.$field) for field in fieldnames(T)]
    docstr   = """
            $name(section::$name; kwargs...) -> $name

        Create a copy of `section`, overriding the fields specified in `kwargs...`.
        """

    @eval @doc $docstr function $name(section::$name; kwargs...)
        return $name(; $(keywords...), kwargs...)
    end
end

# == Validation ============================================================================

"""
    _omm_check_rules(version::VersionNumber, data::OmmData) -> Nothing

Check the rules relating the fields of an Orbit Mean-Elements Message (OMM) with `version`
and data section `data`, throwing an `ArgumentError` if they are violated: the version
must be 2.0 or 3.0, exactly one of `semi_major_axis` and `mean_motion` must be set, and
the TLE-related parameters section, when present, must contain `mean_motion_dot` and
exactly one of `bstar` and `bterm` and of `mean_motion_ddot` and `agom`.

The TLE-related parameters section is present when any of its fields or comments is set.
The predicate must match the one used by the parsers.
"""
function _omm_check_rules(version::VersionNumber, data::OmmData)
    version ∈ (v"2.0", v"3.0") ||
        throw(ArgumentError("Unsupported OMM version: $version."))

    (isnothing(data.semi_major_axis) == isnothing(data.mean_motion)) && throw(
        ArgumentError(
            "Exactly one of `semi_major_axis` and `mean_motion` must be provided."
        ),
    )

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
        (isnothing(data.bstar) == isnothing(data.bterm)) && throw(
            ArgumentError(
                "Exactly one of `bstar` and `bterm` is required in TLE parameters."
            ),
        )
        isnothing(data.mean_motion_dot) &&
            throw(ArgumentError("`mean_motion_dot` is required in TLE parameters."))
        (isnothing(data.mean_motion_ddot) == isnothing(data.agom)) && throw(
            ArgumentError(
                "Exactly one of `mean_motion_ddot` and `agom` is required in TLE " *
                "parameters.",
            ),
        )
    end

    return nothing
end

# == Property Forwarding ===================================================================

# Forward the section fields as properties of the message, so that `omm.epoch` is
# equivalent to `omm.data.epoch`. The `comments` field exists in every section, hence it is
# not forwarded. The generated `getproperty` is a chain of `Symbol` comparisons, which the
# compiler folds to a single field access for a literal property name.
let forwarded = Pair{Symbol, Expr}[]
    for (section, T) in ((:header, OmmHeader), (:metadata, OmmMetadata), (:data, OmmData))
        for field in fieldnames(T)
            field === :comments && continue
            section_expr = :(getfield(omm, $(QuoteNode(section))))
            push!(forwarded, field => :(getfield($section_expr, $(QuoteNode(field)))))
        end
    end

    branches = foldr(
        (p, acc) -> :(name === $(QuoteNode(first(p))) ? $(last(p)) : $acc),
        forwarded;
        init = :(getfield(omm, name)),
    )

    property_names = (fieldnames(OrbitMeanElementsMessage)..., first.(forwarded)...)

    @eval begin
        function Base.getproperty(omm::OrbitMeanElementsMessage, name::Symbol)
            return $branches
        end

        Base.propertynames(::OrbitMeanElementsMessage, ::Bool = false) = $property_names
    end
end

# == Fetchers ==============================================================================

"""
    abstract type AbstractOmmFetcher

Supertype of all Orbit Mean-Elements Message (OMM) fetchers.

Every supported service defines a concrete subtype (e.g. [`CelestrakOmmFetcher`](@ref))
together with methods for [`create_omm_fetcher`](@ref) and [`fetch_omms`](@ref).
"""
abstract type AbstractOmmFetcher end
