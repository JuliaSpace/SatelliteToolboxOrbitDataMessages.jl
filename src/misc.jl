## Description #############################################################################
#
# Miscellaneous utility functions.
#
############################################################################################

"""
    _odm_prepare_input(str::AbstractString, format::Symbol) -> Tuple{AbstractString, Symbol}

Prepare the input `str` of a parsing function, returning it without a leading byte-order
mark together with its resolved `format`. If `format` is `:auto`, the format is inferred
from the content: an input starting with an XML tag is `:xml`, and anything else is
`:kvn`. An `ArgumentError` is thrown if `format` is not `:auto`, `:xml`, or `:kvn`.
"""
function _odm_prepare_input(str::AbstractString, format::Symbol)
    # Remove a leading byte-order mark, which some real-world files include and would
    # otherwise break the format detection and the KVN parser.
    str = chopprefix(str, "\ufeff")

    if format == :auto
        format = occursin(r"^\s*<", str) ? :xml : :kvn
    end

    _odm_check_output_format(format)

    return str, format
end

"""
    _odm_output_format(file::AbstractString, format::Symbol) -> Symbol

Resolve the output `format` of a writing function for the file at `file`. If `format` is
`:auto`, it is inferred from the file extension (case-insensitive): `.kvn` selects `:kvn`,
whereas any other extension selects `:xml`. An `ArgumentError` is thrown if `format` is
not `:auto`, `:xml`, or `:kvn`.
"""
function _odm_output_format(file::AbstractString, format::Symbol)
    if format == :auto
        # Lowercase only the extension instead of copying the whole path.
        format = lowercase(last(splitext(file))) == ".kvn" ? :kvn : :xml
    end

    _odm_check_output_format(format)

    return format
end

"""
    _odm_check_output_format(format::Symbol) -> Nothing

Throw an `ArgumentError` if `format` is neither `:xml` nor `:kvn`.
"""
function _odm_check_output_format(format::Symbol)
    format ∈ (:xml, :kvn) || throw(ArgumentError("Unsupported format: $format."))
    return nothing
end

"""
    _ndm_render_value(value::String) -> String
    _ndm_render_value(value::NanoDate) -> String
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
    _ascii_iequal(a::AbstractString, b::AbstractString) -> Bool

Check if the strings `a` and `b` are equal ignoring the case of the ASCII letters. The
other code units are compared exactly, so the function is safe for any UTF-8 input, and it
does not allocate.
"""
function _ascii_iequal(a::AbstractString, b::AbstractString)
    ncodeunits(a) == ncodeunits(b) || return false

    for i in 1:ncodeunits(a)
        ca = codeunit(a, i)
        cb = codeunit(b, i)
        ca == cb && continue

        # Fold the ASCII letters to lowercase before comparing them.
        fa = ca | 0x20
        (fa == (cb | 0x20)) && (UInt8('a') <= fa <= UInt8('z')) || return false
    end

    return true
end

"""
    _parse_omm_object_id(object_id::AbstractString) -> Union{Nothing, NamedTuple}

Parse an OMM `OBJECT_ID` in the international designator format `YYYY-NNN` or `YYYY-NNNP`,
returning the container `(; year, launch_number, piece)` with the matched components, or
`nothing` if `object_id` does not follow the format. Surrounding whitespace is ignored,
and the piece may be empty.
"""
function _parse_omm_object_id(object_id::AbstractString)
    m = match(r"^(\d{4})-(\d{1,3})([A-Z]*)$", strip(object_id))
    isnothing(m) && return nothing

    # All three groups always participate in a successful match (the piece may be an empty
    # string), so the captures can be asserted to concrete `SubString`s.
    return (;
        year          = m.captures[1]::SubString{String},
        launch_number = m.captures[2]::SubString{String},
        piece         = m.captures[3]::SubString{String},
    )
end

"""
    _parse_ndm_date(str::AbstractString) -> Union{Nothing, NanoDate}

Parse an NDM date/time string into a `NanoDate`, returning `nothing` if `str` is empty or
contains only whitespace. An `ArgumentError` is thrown if the date is malformed or the
ordinal day is outside the year.

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

    1 <= day_of_yr <= daysinyear(year) ||
        throw(ArgumentError("Invalid ordinal day $day_of_yr for year $year."))

    # Build the calendar date from the year and day-of-year.
    date = Date(year, 1, 1) + Day(day_of_yr - 1)
    cal  = Dates.format(date, dateformat"yyyy-mm-dd")

    return NanoDate("$(cal)T$(rest)")
end
