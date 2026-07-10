## Description #############################################################################
#
# Functions related to XML handling.
#
############################################################################################

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _xml_add_tag!(parent::XML.Node, tag::String, value::Any) -> Nothing

Add a child XML tag to `parent` with the given `tag` name and `value`.
"""
function _xml_add_tag!(parent::XML.Node, tag::String, value::Any)
    isnothing(value) && return nothing
    child = XML.Element(tag)
    push!(child, XML.Text(_xml_render(value)))
    push!(parent, child)
    return nothing
end

"""
    _xml_render(value::T) -> String

Render the given `value` of type `T` as a string suitable for XML.

`NanoDate` values are rendered with nanosecond precision (`yyyy-mm-ddTHH:MM:SS.sssssssss`).
"""
_xml_render(value::String) = value
_xml_render(value::Any) = string(value)
function _xml_render(value::NanoDate)
    return Dates.format(value, dateformat"yyyy-mm-ddTHH:MM:SS.sssssssss")
end

"""
    _parse_ndm_date(str::AbstractString) -> NanoDate

Parse an NDM date/time string into a `NanoDate`.

The CCSDS 502.0-B-3 standard allows two formats for absolute time tags and epochs:

  - `YYYY-MM-DDThh:mm:ss[.d→d][Z]` (calendar date)
  - `YYYY-DDDThh:mm:ss[.d→d][Z]` (ordinal day-of-year)

`NanoDate` natively handles the calendar form (including the optional trailing `Z`), so this
function only needs to convert the ordinal form before delegating to `NanoDate`.
"""
function _parse_ndm_date(str::AbstractString)
    # Try the calendar format first (the common case).
    m = match(r"^(\d{4})-(\d{3})T(.*)$", str)

    isnothing(m) && return NanoDate(str)

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
