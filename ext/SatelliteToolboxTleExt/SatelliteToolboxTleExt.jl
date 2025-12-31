module SatelliteToolboxTleExt

using Dates
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
    epoch_dt   = DateTime(data.epoch)
    epoch_year = mod(year(epoch_dt), 100)
    midnight   = DateTime(Date(epoch_dt))
    epoch_day  = dayofyear(epoch_dt) + Dates.value(epoch_dt - midnight) / (1000 * 86400)

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

    # TODO: The specification is not clear if the fields in OMM are already adjusted
    # according to the SGP4 algorithm. By fetching OMMs from Celestrak and Spacetrack, I
    # noticed that the provided values are already divided by the necessary factors. So, for
    # now, we assume they are already adjusted. This may need to be revisited later.
    dn_o2  = something(data.mean_motion_dot,  0.0)
    ddn_o6 = something(data.mean_motion_ddot, 0.0)

    return TLE(;
        # == Name ==========================================================================
        name                     = metadata.object_name,

        # == First Line ====================================================================
        satellite_number         = something(data.norad_cat_id, 0),
        classification           = something(data.classification_type, 'U'),
        international_designator = _omm_object_id_to_tle_intl_designator(metadata.object_id),
        epoch_year               = epoch_year,
        epoch_day                = epoch_day,
        dn_o2                    = dn_o2,
        ddn_o6                   = ddn_o6,
        bstar                    = something(data.bstar, 0.0),
        element_set_number       = something(data.element_set_number, 0),

        # == Second Line ===================================================================
        inclination              = data.inclination,
        raan                     = data.raan,
        eccentricity             = data.eccentricity,
        argument_of_perigee      = data.arg_of_pericenter,
        mean_anomaly             = data.mean_anomaly,
        mean_motion              = mean_motion,
        revolution_number        = something(data.rev_at_epoch, 0),
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