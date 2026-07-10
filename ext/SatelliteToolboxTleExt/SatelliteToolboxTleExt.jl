module SatelliteToolboxTleExt

using Dates
using NanoDates
using SatelliteToolboxOrbitDataMessages
using SatelliteToolboxTle

import Base: convert

############################################################################################
#                                        Julia API                                         #
############################################################################################

function convert(::Type{TLE}, omm::OrbitMeanElementsMessage)
    # We should only convert to TLE if the mean element theory is SGP4.
    omm.body.segment.metadata.mean_element_theory != "SGP4" &&
        error("Cannot convert OMM to TLE because the mean element theory is not SGP4.")

    # Extract the necessary fields from the OMM.
    data     = omm.body.segment.data
    metadata = omm.body.segment.metadata

    # Convert the epoch to TLE format.
    epoch_year = mod(year(data.epoch), 100)
    midnight   = NanoDate(Date(data.epoch))
    epoch_day  = dayofyear(data.epoch) +
        Dates.value(data.epoch - midnight) / (1_000_000_000 * 86400)

    # Obtain the mean motion from the parameters.
    mean_motion = data.mean_motion

    if isnothing(mean_motion)
        isnothing(data.semi_major_axis) && error(
            "Cannot compute mean motion from OMM: missing semi-major axis.",
        )
        isnothing(data.GM) && error(
            "Cannot compute mean motion from OMM: missing GM.",
        )

        GM = data.GM
        a  = data.semi_major_axis

        mean_motion = √(GM / a^3) / (2π) * 86400
    end

    # The specification is not clear if the fields in OMM are already adjusted
    # according to the SGP4 algorithm. Observations of Celestrak and Spacetrack OMMs show
    # that the provided values are already divided by the necessary factors. So, for now,
    # we assume they are already adjusted. This may need to be revisited later.
    isnothing(data.bterm) || error("Cannot convert OMM `BTERM` to a TLE `BSTAR` field.")
    isnothing(data.agom) || error("Cannot convert OMM `AGOM` to a TLE mean-motion field.")

    required_fields = (
        ("classification_type", data.classification_type),
        ("norad_cat_id", data.norad_cat_id),
        ("element_set_number", data.element_set_number),
        ("rev_at_epoch", data.rev_at_epoch),
        ("bstar", data.bstar),
        ("mean_motion_dot", data.mean_motion_dot),
        ("mean_motion_ddot", data.mean_motion_ddot),
    )

    for (name, value) in required_fields
        isnothing(value) && error("Cannot convert OMM to TLE: missing `$name`.")
    end

    return TLE(;
        # == Name ==========================================================================
        name                     = metadata.object_name,

        # == First Line ====================================================================
        satellite_number         = data.norad_cat_id,
        classification           = data.classification_type,
        international_designator =
            _omm_object_id_to_tle_intl_designator(metadata.object_id),
        epoch_year               = epoch_year,
        epoch_day                = epoch_day,
        dn_o2                    = data.mean_motion_dot,
        ddn_o6                   = data.mean_motion_ddot,
        bstar                    = data.bstar,
        element_set_number       = data.element_set_number,

        # == Second Line ===================================================================
        inclination              = data.inclination,
        raan                     = data.raan,
        eccentricity             = data.eccentricity,
        argument_of_perigee      = data.arg_of_pericenter,
        mean_anomaly             = data.mean_anomaly,
        mean_motion              = mean_motion,
        revolution_number        = data.rev_at_epoch,
    )
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _omm_object_id_to_tle_intl_designator(object_id::String) -> String

Convert an OMM `OBJECT_ID` (format: `YYYY-NNNX` or `YYYY-NNN` or similar variations) to
a TLE international designator (format: `YYNNNXXX`).

The OMM format is typically `1998-067A` while TLE format is `98067A`.
"""
function _omm_object_id_to_tle_intl_designator(object_id::String)
    # Remove any whitespace.
    obj_id = strip(object_id)

    # Try to match the pattern YYYY-NNN[piece].
    m = match(r"^(\d{4})-(\d{1,3})([A-Z]*)$", obj_id)

    # If the pattern does not match, return as-is (fallback).
    isnothing(m) && return obj_id

    # Obtain the captures.
    year       = m.captures[1]
    launch_num = m.captures[2]
    piece      = something(m.captures[3], "")

    # Take last 2 digits of year.
    year_2digit = @views year[3:4]

    # Pad launch number to 3 digits
    launch_num_padded = lpad(launch_num, 3, "0")

    return year_2digit * launch_num_padded * piece
end

end # module SatelliteToolboxTleExt
