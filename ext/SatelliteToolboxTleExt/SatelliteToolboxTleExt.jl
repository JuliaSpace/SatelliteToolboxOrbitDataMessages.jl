## Description #############################################################################
#
# Extension with the conversion from Orbit Mean-Elements Messages (OMM) to TLEs.
#
############################################################################################

module SatelliteToolboxTleExt

using Dates
using NanoDates
using SatelliteToolboxOrbitDataMessages
using SatelliteToolboxTle

import Base: convert
import SatelliteToolboxOrbitDataMessages: _parse_omm_object_id

# Number of nanoseconds in one day, used to convert an epoch time of day to a day
# fraction.
const _NANOSECONDS_PER_DAY = 86_400 * 1_000_000_000

############################################################################################
#                                        Julia API                                         #
############################################################################################

"""
    convert(::Type{TLE}, omm::OrbitMeanElementsMessage) -> TLE

Convert the Orbit Mean-Elements Message `omm` to a `TLE`.

The mean element theory of `omm` must be `"SGP4"`, and the message must provide the
TLE-related parameters `CLASSIFICATION_TYPE`, `NORAD_CAT_ID`, `ELEMENT_SET_NO`,
`REV_AT_EPOCH`, `BSTAR`, `MEAN_MOTION_DOT`, and `MEAN_MOTION_DDOT`. The mean motion
[rev/day] is taken from the message or computed from the semi-major axis and `GM` when
absent. An `ErrorException` is thrown if any required information is missing or the
message uses `BTERM` or `AGOM` instead of `BSTAR` and `MEAN_MOTION_DDOT`.

The epoch is converted to the two-digit year and day-of-year form used by the TLE format,
keeping the time system of the message. `MEAN_MOTION_DOT` [rev/day²] and
`MEAN_MOTION_DDOT` [rev/day³] are copied directly into the TLE fields `dn_o2` and
`ddn_o6`, assuming that the message values are already divided by 2 and 6, respectively,
as observed in Celestrak and Space-Track products.
"""
function convert(::Type{TLE}, omm::OrbitMeanElementsMessage)
    # We should only convert to TLE if the mean element theory is SGP4.
    omm.metadata.mean_element_theory != "SGP4" &&
        error("Cannot convert OMM to TLE because the mean element theory is not SGP4.")

    # Extract the necessary fields from the OMM.
    data     = omm.data
    metadata = omm.metadata

    # Convert the epoch to TLE format.
    epoch_year = mod(year(data.epoch), 100)
    epoch_day  =
        dayofyear(data.epoch) +
        Dates.value(data.epoch - Date(data.epoch)) / _NANOSECONDS_PER_DAY

    # Obtain the mean motion from the parameters.
    mean_motion = data.mean_motion

    if isnothing(mean_motion)
        isnothing(data.semi_major_axis) &&
            error("Cannot compute mean motion from OMM: missing semi-major axis.")
        isnothing(data.GM) && error("Cannot compute mean motion from OMM: missing GM.")

        GM = data.GM
        a  = data.semi_major_axis

        mean_motion = √(GM / a^3) / (2π) * 86400
    end

    # The specification is not clear if the fields in OMM are already adjusted
    # according to the SGP4 algorithm. Observations of Celestrak and Spacetrack OMMs show
    # that the provided values are already divided by the necessary factors. So, for now,
    # we assume they are already adjusted. This may need to be revisited later.
    isnothing(data.bterm) || error("Cannot convert OMM `BTERM` to the TLE `BSTAR` field.")
    isnothing(data.agom) || error(
        "Cannot convert OMM `AGOM` to the TLE mean-motion second derivative field."
    )

    # The fields are named by their CCSDS keywords so that the error messages match the
    # source message contents.
    required_fields = (
        ("CLASSIFICATION_TYPE", data.classification_type),
        ("NORAD_CAT_ID", data.norad_cat_id),
        ("ELEMENT_SET_NO", data.element_set_number),
        ("REV_AT_EPOCH", data.rev_at_epoch),
        ("BSTAR", data.bstar),
        ("MEAN_MOTION_DOT", data.mean_motion_dot),
        ("MEAN_MOTION_DDOT", data.mean_motion_ddot),
    )

    for (name, value) in required_fields
        isnothing(value) && error("Cannot convert OMM to TLE: missing `$name`.")
    end

    return TLE(;
        # == Name ==========================================================================
        name = metadata.object_name,

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
        inclination         = data.inclination,
        raan                = data.raan,
        eccentricity        = data.eccentricity,
        argument_of_perigee = data.arg_of_pericenter,
        mean_anomaly        = data.mean_anomaly,
        mean_motion         = mean_motion,
        revolution_number   = data.rev_at_epoch,
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
    # Try to match the pattern YYYY-NNN[piece].
    parsed = _parse_omm_object_id(object_id)

    # If the pattern does not match, return the identifier without the surrounding
    # whitespace (fallback).
    isnothing(parsed) && return String(strip(object_id))

    # Take the last 2 digits of the year and pad the launch number to 3 digits.
    year_2digit       = @views parsed.year[3:4]
    launch_num_padded = lpad(parsed.launch_number, 3, "0")

    return string(year_2digit, launch_num_padded, parsed.piece)
end

end # module SatelliteToolboxTleExt
