## Description #############################################################################
#
# Miscellaneous utility functions.
#
############################################################################################

"""
    _ndm_render_value(value::Any) -> String

Render the given `value` as a string suitable for NDM outputs (e.g. XML or KVN).

`NanoDate` values are rendered with nanosecond precision
(`yyyy-mm-ddTHH:MM:SS.sssssssss`), whereas the other types use their default string
representation. Notice that, for `AbstractFloat`, this representation is the shortest one
that round-trips exactly, avoiding any loss of precision.
"""
_ndm_render_value(value::String) = value
_ndm_render_value(value::Any) = string(value)

function _ndm_render_value(value::NanoDate)
    return Dates.format(value, dateformat"yyyy-mm-ddTHH:MM:SS.sssssssss")
end

"""
    _parse_ndm_date(str::AbstractString) -> Union{Nothing, NanoDate}

Parse an NDM date/time string into a `NanoDate`, returning `nothing` if `str` is empty or
contains only whitespace.

The CCSDS 502.0-B-3 standard allows two formats for absolute time tags and epochs:

  - `YYYY-MM-DDThh:mm:ss[.d→d][Z]` (calendar date)
  - `YYYY-DDDThh:mm:ss[.d→d][Z]` (ordinal day-of-year)

`NanoDate` natively handles the calendar form (including the optional trailing `Z`), so this
function only needs to convert the ordinal form before delegating to `NanoDate`.
"""
function _parse_ndm_date(str::AbstractString)
    sstr = strip(str)
    isempty(sstr) && return nothing

    # Check for the ordinal day-of-year format. If it does not match, fall back to the
    # calendar format (the common case), which `NanoDate` handles natively.
    m = match(r"^(\d{4})-(\d{3})T(.*)$", sstr)

    isnothing(m) && return NanoDate(sstr)

    # Ordinal day-of-year form: convert DDD → MM-DD.
    year      = parse(Int, m[1])
    day_of_yr = parse(Int, m[2])
    rest      = m[3]

    1 <= day_of_yr <= daysinyear(year) || throw(ArgumentError(
        "Invalid ordinal day $day_of_yr for year $year."
    ))

    # Build the calendar date from the year and day-of-year.
    date = Date(year, 1, 1) + Day(day_of_yr - 1)
    cal  = Dates.format(date, dateformat"yyyy-mm-dd")

    return NanoDate("$(cal)T$(rest)")
end
