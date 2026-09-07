## Description #############################################################################
#
# Extension with the conversions between Orbit Mean-Elements Messages (OMM) and TLEs.
#
############################################################################################

module SatelliteToolboxTleExt

using Dates
using NanoDates
using SatelliteToolboxOrbitDataMessages
using SatelliteToolboxTle

import Base: convert
import SatelliteToolboxOrbitDataMessages: OrbitMeanElementsMessage, _parse_omm_object_id

############################################################################################
#                                        Constants                                         #
############################################################################################

# Number of nanoseconds in one day, used to convert between an epoch time of day and a day
# fraction.
const _NANOSECONDS_PER_DAY = 86_400 * 1_000_000_000

# Number of microseconds in one day, used to round the TLE epoch to the microsecond.
const _MICROSECONDS_PER_DAY = 86_400 * 1_000_000

# Pivot of the two-digit years used by the TLE format, in the epoch and in the international
# designator, following the SGP4 reference implementation: years from 57 to 99 refer to the
# 20th century, and years from 0 to 56 to the 21st century. Hence, a TLE can only represent
# the years in the interval [1957, 2056].
const _TLE_YEAR_PIVOT = 57
const _TLE_FIRST_YEAR = 1900 + _TLE_YEAR_PIVOT
const _TLE_LAST_YEAR  = 2000 + _TLE_YEAR_PIVOT - 1

# Pattern of a TLE international designator: a two-digit launch year, the launch number of
# the year, and an optional launch piece. The launch number has three digits in the TLE
# format, but fewer digits are accepted for robustness.
const _TLE_INTL_DESIGNATOR_REGEX = r"^(\d{2})(\d{1,3})([A-Z]*)$"

############################################################################################
#                                        Julia API                                         #
############################################################################################

# == OMM to TLE ============================================================================

"""
    convert(::Type{TLE}, omm::OrbitMeanElementsMessage) -> TLE

Convert the Orbit Mean-Elements Message `omm` to a `TLE`.

The mean element theory of `omm` must be `"SGP4"`, and the message must provide the
TLE-related parameters `CLASSIFICATION_TYPE`, `NORAD_CAT_ID`, `ELEMENT_SET_NO`,
`REV_AT_EPOCH`, `BSTAR`, `MEAN_MOTION_DOT`, and `MEAN_MOTION_DDOT`. `EPHEMERIS_TYPE` is
copied when present and defaults to 0 otherwise. The mean motion [rev/day] is taken from
the message or computed from the semi-major axis and `GM` when absent. An `ErrorException`
is thrown if any required information is missing, if the message uses `BTERM` or `AGOM`
instead of `BSTAR` and `MEAN_MOTION_DDOT`, or if the epoch year is outside the interval
[1957, 2056] that the two-digit TLE year can represent. An `ArgumentError` is thrown if a
field cannot be represented in the TLE format (see the `TLE` constructor).

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

    # == Epoch =============================================================================

    epoch_year, epoch_day = _nanodate_to_tle_epoch(data.epoch)

    # == Mean Motion =======================================================================

    mean_motion = data.mean_motion

    if isnothing(mean_motion)
        isnothing(data.semi_major_axis) &&
            error("Cannot compute mean motion from OMM: missing semi-major axis.")
        isnothing(data.GM) && error("Cannot compute mean motion from OMM: missing GM.")

        GM = data.GM
        a  = data.semi_major_axis

        mean_motion = √(GM / a^3) / (2π) * 86400
    end

    # == TLE-Related Parameters ============================================================

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
        ephemeris_type           = something(data.ephemeris_type, 0),
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

# == TLE to OMM ============================================================================

"""
    OrbitMeanElementsMessage(tle::TLE; kwargs...) -> OrbitMeanElementsMessage

Create an Orbit Mean-Elements Message (OMM) with version 3.0 from `tle`, overriding the
fields specified in `kwargs...`. Any keyword accepted by the keyword constructor
`OrbitMeanElementsMessage(; kwargs...)` can be used.

The mean Keplerian elements and the TLE-related parameters are copied from `tle`, and the
metadata describes the conventions of the TLE format: the center name is `"EARTH"`, the
reference frame is `"TEME"`, the time system is `"UTC"`, and the mean element theory is
`"SGP4"`. The TLE fields `dn_o2` [rev/day²] and `ddn_o6` [rev/day³] are copied directly
into `MEAN_MOTION_DOT` and `MEAN_MOTION_DDOT`, as in the conversion from OMM to TLE.

The two-digit years of the TLE epoch and of the international designator are interpreted
as in the SGP4 reference implementation: years from 57 to 99 refer to the 20th century,
and years from 0 to 56 to the 21st century. The epoch is rounded to the microsecond, which
is far below the resolution of the TLE epoch field (1e-8 day, or 0.864 ms) and matches the
precision used by Celestrak and Space-Track. The international designator (e.g. `21015A`)
is translated to the OMM `OBJECT_ID` format (e.g. `2021-015A`); a designator that does not
follow the TLE format is copied as is.

The header receives the current UTC time, truncated to the second, as creation date and
this package as originator, which are the fields most likely to be overridden with
`kwargs...`. The header classification and the message identifier are left unset.
"""
function OrbitMeanElementsMessage(tle::TLE; kwargs...)
    package_version = pkgversion(SatelliteToolboxOrbitDataMessages)

    return OrbitMeanElementsMessage(;
        # == Header ========================================================================
        creation_date = NanoDate(trunc(now(UTC), Second)),
        originator    = "SatelliteToolboxOrbitDataMessages.jl v$package_version",

        # == Metadata ======================================================================
        object_name         = tle.name,
        object_id           = _tle_intl_designator_to_omm_object_id(
            tle.international_designator
        ),
        center_name         = "EARTH",
        ref_frame           = "TEME",
        time_system         = "UTC",
        mean_element_theory = "SGP4",

        # == Mean Keplerian Elements =======================================================
        epoch             = _tle_epoch_to_nanodate(tle.epoch_year, tle.epoch_day),
        mean_motion       = tle.mean_motion,
        eccentricity      = tle.eccentricity,
        inclination       = tle.inclination,
        raan              = tle.raan,
        arg_of_pericenter = tle.argument_of_perigee,
        mean_anomaly      = tle.mean_anomaly,

        # == TLE-Related Parameters ========================================================
        ephemeris_type      = tle.ephemeris_type,
        classification_type = tle.classification,
        norad_cat_id        = tle.satellite_number,
        element_set_number  = tle.element_set_number,
        rev_at_epoch        = tle.revolution_number,
        bstar               = tle.bstar,
        mean_motion_dot     = tle.dn_o2,
        mean_motion_ddot    = tle.ddn_o6,

        # == Overrides =====================================================================
        kwargs...,
    )
end

"""
    convert(::Type{OrbitMeanElementsMessage}, tle::TLE) -> OrbitMeanElementsMessage

Convert the `tle` to an Orbit Mean-Elements Message (OMM) with the default header, as
described in `OrbitMeanElementsMessage(tle::TLE; kwargs...)`.
"""
convert(::Type{OrbitMeanElementsMessage}, tle::TLE) = OrbitMeanElementsMessage(tle)

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# == Epoch =================================================================================

"""
    _nanodate_to_tle_epoch(epoch::NanoDate) -> Int, Float64

Convert `epoch` to the two-digit year and the day of the year plus its fraction [days]
used by the TLE format. An `ErrorException` is thrown if the year of `epoch` cannot be
represented by the two-digit TLE year (see `_tle_epoch_to_nanodate`).
"""
function _nanodate_to_tle_epoch(epoch::NanoDate)
    epoch_year = year(epoch)

    (_TLE_FIRST_YEAR <= epoch_year <= _TLE_LAST_YEAR) || error(
        "Cannot convert OMM to TLE: the epoch year must be in the interval " *
        "[$_TLE_FIRST_YEAR, $_TLE_LAST_YEAR].",
    )

    # The time of day is computed in nanoseconds to keep the sub-millisecond precision of
    # the epoch, whose Float64 representation has a resolution of a few nanoseconds.
    time_of_day = Dates.value(epoch - Date(epoch))
    epoch_day   = dayofyear(epoch) + time_of_day / _NANOSECONDS_PER_DAY

    return mod(epoch_year, 100), epoch_day
end

"""
    _tle_epoch_to_nanodate(epoch_year::Int, epoch_day::Float64) -> NanoDate

Convert the TLE epoch, given by the two-digit `epoch_year` and the day of the year plus its
fraction `epoch_day` [days], to a `NanoDate` rounded to the microsecond.

The two-digit year is interpreted with the SGP4 reference pivot (see `_tle_year`). The
day fraction cannot be converted exactly to nanoseconds, since its Float64 representation
has a resolution of a few nanoseconds, so the result is rounded to the microsecond. This
precision is far below the resolution of the TLE epoch field (1e-8 day, or 0.864 ms) and
matches the epochs of the Celestrak and Space-Track messages.
"""
function _tle_epoch_to_nanodate(epoch_year::Int, epoch_day::Float64)
    # Split the epoch day into the day of the year and the time of day, so that the
    # fraction is scaled with the full Float64 precision.
    day_of_year = floor(Int, epoch_day)
    time_of_day = Microsecond(round(Int, (epoch_day - day_of_year) * _MICROSECONDS_PER_DAY))

    # The day of the year starts at 1, so the first day of the year adds no days.
    return NanoDate(_tle_year(epoch_year)) + Day(day_of_year - 1) + time_of_day
end

"""
    _tle_year(two_digit_year::Int) -> Int

Return the four-digit year related to the two-digit TLE year `two_digit_year`, using the
pivot of the SGP4 reference implementation: years from 57 to 99 refer to the 20th century,
and years from 0 to 56 to the 21st century.
"""
function _tle_year(two_digit_year::Int)
    return two_digit_year >= _TLE_YEAR_PIVOT ? 1900 + two_digit_year : 2000 + two_digit_year
end

# == International Designator ==============================================================

"""
    _omm_object_id_to_tle_intl_designator(object_id::String) -> String

Convert an OMM `OBJECT_ID` (format: `YYYY-NNNP`, where the launch piece `P` is optional)
to a TLE international designator (format: `YYNNNP`), e.g. `2021-015A` to `21015A`. An
`OBJECT_ID` that does not follow the format is returned without the surrounding
whitespace.
"""
function _omm_object_id_to_tle_intl_designator(object_id::String)
    parsed = _parse_omm_object_id(object_id)

    isnothing(parsed) && return String(strip(object_id))

    # Take the last two digits of the year and pad the launch number to three digits.
    year_2digit       = @views parsed.year[3:4]
    launch_num_padded = lpad(parsed.launch_number, 3, '0')

    return string(year_2digit, launch_num_padded, parsed.piece)
end

"""
    _tle_intl_designator_to_omm_object_id(intl_designator::String) -> String

Convert a TLE international designator (format: `YYNNNP`, where the launch piece `P` is
optional) to an OMM `OBJECT_ID` (format: `YYYY-NNNP`), e.g. `21015A` to `2021-015A`. The
two-digit year is interpreted with the SGP4 reference pivot (see `_tle_year`). A
designator that does not follow the format is returned without the surrounding
whitespace.
"""
function _tle_intl_designator_to_omm_object_id(intl_designator::String)
    stripped = strip(intl_designator)
    m        = match(_TLE_INTL_DESIGNATOR_REGEX, stripped)

    isnothing(m) && return String(stripped)

    # All three groups always participate in a successful match (the piece may be an empty
    # string), so the captures can be asserted to concrete `SubString`s.
    year          = _tle_year(parse(Int, m.captures[1]::SubString{String}))
    launch_number = lpad(m.captures[2]::SubString{String}, 3, '0')
    piece         = m.captures[3]::SubString{String}

    return string(year, '-', launch_number, piece)
end

end # module SatelliteToolboxTleExt
