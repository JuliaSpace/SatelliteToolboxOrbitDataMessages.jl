## Description #############################################################################
#
# Accessor functions for the Orbit Data Messages.
#
############################################################################################

export ODM

"""
    module ODM

Namespace with accessor functions for the fields of Orbit Data Messages (ODM).

The accessors flatten the nested CCSDS hierarchy so that the most common fields can be
obtained without navigating the message structure, e.g. `ODM.epoch(omm)` instead of
`omm.body.segment.data.epoch`. The functions live in this module to avoid polluting the
namespace with the field names; access them qualified, or opt in with
`using SatelliteToolboxOrbitDataMessages.ODM`.
"""
module ODM

using ..SatelliteToolboxOrbitDataMessages: OrbitMeanElementsMessage

# Each table entry is `(accessor, field, return type, description)`. The accessors are
# generated mechanically to guarantee that every field has one and that the docstrings
# stay consistent.

# == Header Accessors ======================================================================

const _OMM_HEADER_ACCESSORS = (
    (:header_comments, :comments, "Vector{String}", "the comments of the header section"),
    (:classification, :classification, "Union{String, Nothing}", "the classification"),
    (:creation_date, :creation_date, "Union{NanoDate, Nothing}", "the creation date"),
    (:originator, :originator, "String", "the originator"),
    (:message_id, :message_id, "Union{String, Nothing}", "the message identifier"),
)

for (fname, field, rtype, desc) in _OMM_HEADER_ACCESSORS
    docstr = """
            ODM.$fname(omm::OrbitMeanElementsMessage) -> $rtype

        Return $desc of the Orbit Mean-Elements Message `omm`.
        """
    @eval begin
        export $fname
        @doc $docstr $fname(omm::OrbitMeanElementsMessage) = omm.header.$field
    end
end

# == Metadata Accessors ====================================================================

const _OMM_METADATA_ACCESSORS = (
    (
        :metadata_comments,
        :comments,
        "Vector{String}",
        "the comments of the metadata section"
    ),
    (:object_name, :object_name, "String", "the spacecraft name"),
    (:object_id, :object_id, "String", "the international designator"),
    (:center_name, :center_name, "String", "the origin of the reference frame"),
    (:ref_frame, :ref_frame, "String", "the reference frame of the mean elements"),
    (
        :ref_frame_epoch,
        :ref_frame_epoch,
        "Union{NanoDate, Nothing}",
        "the epoch of the reference frame"
    ),
    (:time_system, :time_system, "String", "the time system"),
    (
        :mean_element_theory,
        :mean_element_theory,
        "String",
        "the theory describing the mean elements"
    ),
)

for (fname, field, rtype, desc) in _OMM_METADATA_ACCESSORS
    docstr = """
            ODM.$fname(omm::OrbitMeanElementsMessage) -> $rtype

        Return $desc of the Orbit Mean-Elements Message `omm`.
        """
    @eval begin
        export $fname
        @doc $docstr $fname(omm::OrbitMeanElementsMessage) = omm.body.segment.metadata.$field
    end
end

# == Data Accessors ========================================================================

const _OMM_DATA_ACCESSORS = (
    (:data_comments, :comments, "Vector{String}", "the comments of the data section"),
    (
        :mean_elements_comments,
        :mean_elements_comments,
        "Vector{String}",
        "the comments of the mean elements section"
    ),
    (:epoch, :epoch, "NanoDate", "the epoch of the mean Keplerian elements"),
    (
        :semi_major_axis,
        :semi_major_axis,
        "Union{Float64, Nothing}",
        "the semi-major axis [km]"
    ),
    (:mean_motion, :mean_motion, "Union{Float64, Nothing}", "the mean motion [rev/day]"),
    (:eccentricity, :eccentricity, "Float64", "the eccentricity"),
    (:inclination, :inclination, "Float64", "the inclination [deg]"),
    (:raan, :raan, "Float64", "the right ascension of the ascending node [deg]"),
    (
        :arg_of_pericenter,
        :arg_of_pericenter,
        "Float64",
        "the argument of pericenter [deg]"
    ),
    (:mean_anomaly, :mean_anomaly, "Float64", "the mean anomaly [deg]"),
    (:GM, :GM, "Union{Float64, Nothing}", "the gravitational coefficient [km³/s²]"),
    (
        :spacecraft_parameters_comments,
        :spacecraft_parameters_comments,
        "Vector{String}",
        "the comments of the spacecraft parameters section"
    ),
    (:mass, :mass, "Union{Float64, Nothing}", "the spacecraft mass [kg]"),
    (
        :solar_rad_area,
        :solar_rad_area,
        "Union{Float64, Nothing}",
        "the effective area for solar radiation pressure [m²]"
    ),
    (
        :solar_rad_coeff,
        :solar_rad_coeff,
        "Union{Float64, Nothing}",
        "the solar radiation pressure coefficient"
    ),
    (
        :drag_area,
        :drag_area,
        "Union{Float64, Nothing}",
        "the effective area for atmospheric drag [m²]"
    ),
    (
        :drag_coeff,
        :drag_coeff,
        "Union{Float64, Nothing}",
        "the atmospheric drag coefficient"
    ),
    (
        :tle_parameters_comments,
        :tle_parameters_comments,
        "Vector{String}",
        "the comments of the TLE-related parameters section"
    ),
    (
        :ephemeris_type,
        :ephemeris_type,
        "Union{Int, Nothing}",
        "the default ephemeris type associated with the TLE"
    ),
    (
        :classification_type,
        :classification_type,
        "Union{Char, Nothing}",
        "the classification type"
    ),
    (:norad_cat_id, :norad_cat_id, "Union{Int, Nothing}", "the NORAD catalog number"),
    (
        :element_set_number,
        :element_set_number,
        "Union{Int, Nothing}",
        "the element set number"
    ),
    (
        :rev_at_epoch,
        :rev_at_epoch,
        "Union{Int, Nothing}",
        "the revolution number at epoch"
    ),
    (:bstar, :bstar, "Union{Float64, Nothing}", "the SGP4 drag term B* [1/earth radii]"),
    (:bterm, :bterm, "Union{Float64, Nothing}", "the ballistic coefficient [m²/kg]"),
    (
        :mean_motion_dot,
        :mean_motion_dot,
        "Union{Float64, Nothing}",
        "the first time derivative of the mean motion [rev/day²]"
    ),
    (
        :mean_motion_ddot,
        :mean_motion_ddot,
        "Union{Float64, Nothing}",
        "the second time derivative of the mean motion [rev/day³]"
    ),
    (
        :agom,
        :agom,
        "Union{Float64, Nothing}",
        "the solar radiation pressure coefficient AGOM [m²/kg]"
    ),
    (
        :covariance_matrix,
        :covariance_matrix,
        "Union{OmmCovarianceMatrix, Nothing}",
        "the covariance matrix"
    ),
    (
        :user_defined_parameters,
        :user_defined_parameters,
        "Union{Nothing, Vector{Pair{String, String}}}",
        "the user-defined parameters"
    ),
)

for (fname, field, rtype, desc) in _OMM_DATA_ACCESSORS
    docstr = """
            ODM.$fname(omm::OrbitMeanElementsMessage) -> $rtype

        Return $desc of the Orbit Mean-Elements Message `omm`.
        """
    @eval begin
        export $fname
        @doc $docstr $fname(omm::OrbitMeanElementsMessage) = omm.body.segment.data.$field
    end
end

end # module ODM
