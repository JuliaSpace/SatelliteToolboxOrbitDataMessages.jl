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
    _ndm_print_value(io::IO, value::Any) -> Nothing

Print the given `value` to `io` in the representation used by the NDM outputs (e.g. XML or
KVN).

`NanoDate` values are printed with nanosecond precision
(`yyyy-mm-ddTHH:MM:SS.sssssssss`), whereas the other types use their default string
representation. Notice that, for `AbstractFloat`, this representation is the shortest one
that round-trips exactly, avoiding any loss of precision.
"""
function _ndm_print_value(io::IO, value::Any)
    print(io, value)
    return nothing
end

function _ndm_print_value(io::IO, value::NanoDate)
    # The digits are written directly, which is far cheaper than `Dates.format`.
    _print_padded(io, year(value), 4)
    write(io, UInt8('-'))
    _print_padded(io, month(value), 2)
    write(io, UInt8('-'))
    _print_padded(io, day(value), 2)
    write(io, UInt8('T'))
    _print_padded(io, hour(value), 2)
    write(io, UInt8(':'))
    _print_padded(io, minute(value), 2)
    write(io, UInt8(':'))
    _print_padded(io, second(value), 2)
    write(io, UInt8('.'))

    nanoseconds =
        1_000_000 * millisecond(value) + 1_000 * microsecond(value) + nanosecond(value)
    _print_padded(io, nanoseconds, 9)

    return nothing
end

"""
    _ndm_render_value(value::Any) -> String

Render the given `value` as a string using [`_ndm_print_value`](@ref). Strings are
returned as they are.
"""
_ndm_render_value(value::String) = value
_ndm_render_value(value::Any) = sprint(_ndm_print_value, value)

"""
    _print_padded(io::IO, x::Integer, width::Int) -> Nothing

Print the non-negative integer `x` to `io` with exactly `width` digits, padding it with
leading zeros. Digits beyond `width` are dropped.
"""
function _print_padded(io::IO, x::Integer, width::Int)
    p = 10^(width - 1)

    while p > 0
        write(io, UInt8('0') + UInt8((x ÷ p) % 10))
        p ÷= 10
    end

    return nothing
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
contains only whitespace. An `ArgumentError` is thrown if the date is malformed or any of
its components is out of range.

The CCSDS 502.0-B-3 standard allows two formats for absolute time tags and epochs:

  - `YYYY-MM-DDThh:mm:ss[.d→d][Z]` (calendar date)
  - `YYYY-DDDThh:mm:ss[.d→d][Z]` (ordinal day-of-year)

The parser additionally accepts a space as the date/time separator and an omitted time,
seconds, or fraction, which appear in some real-world files. The fraction is truncated to
nanoseconds.
"""
function _parse_ndm_date(str::AbstractString)
    sstr = strip(str)
    isempty(sstr) && return nothing

    date = _try_parse_ndm_date(sstr)
    isnothing(date) && throw(ArgumentError("Invalid NDM date: \"$sstr\"."))

    return date
end

"""
    _try_parse_ndm_date(str::AbstractString) -> Union{Nothing, NanoDate}

Parse the NDM date/time string `str`, which must not have surrounding whitespace, returning
`nothing` if it is malformed. See [`_parse_ndm_date`](@ref) for the accepted formats.

The digits are read directly from the code units, avoiding the regular expressions and
the intermediate strings of a `DateFormat`-based parser.
"""
function _try_parse_ndm_date(str::AbstractString)
    cu = codeunits(str)
    n  = length(cu)

    # == Date ==============================================================================

    year, i = _read_digits(cu, 1, 4)
    year < 0 && return nothing

    _read_char(cu, i, '-') || return nothing
    i += 1

    # The calendar form has a `-` after the two-digit month, whereas the ordinal form has
    # three digits.
    if (i + 2 <= n) && (cu[i + 2] == UInt8('-'))
        month, i = _read_digits(cu, i, 2)
        month < 0 && return nothing
        i += 1

        day, i = _read_digits(cu, i, 2)
        day < 0 && return nothing

        (1 <= month <= 12) && (1 <= day <= daysinmonth(year, month)) || return nothing
    else
        day_of_year, i = _read_digits(cu, i, 3)
        day_of_year < 0 && return nothing

        (1 <= day_of_year <= daysinyear(year)) || return nothing

        date  = Date(year, 1, 1) + Day(day_of_year - 1)
        month = Dates.month(date)
        day   = Dates.day(date)
    end

    # == Time ==============================================================================

    hour = minute = second = nanoseconds = 0

    if i <= n
        (_read_char(cu, i, 'T') || _read_char(cu, i, ' ')) || return nothing
        i += 1

        hour, i = _read_digits(cu, i, 2)
        hour < 0 && return nothing

        _read_char(cu, i, ':') || return nothing
        i += 1

        minute, i = _read_digits(cu, i, 2)
        minute < 0 && return nothing

        if _read_char(cu, i, ':')
            i += 1

            second, i = _read_digits(cu, i, 2)
            second < 0 && return nothing

            if _read_char(cu, i, '.')
                i += 1

                nanoseconds, i = _read_fraction(cu, i)
                nanoseconds < 0 && return nothing
            end
        end

        (hour <= 23) && (minute <= 59) && (second <= 59) || return nothing

        _read_char(cu, i, 'Z') && (i += 1)
    end

    # The whole string must have been consumed.
    i == n + 1 || return nothing

    datetime = DateTime(year, month, day, hour, minute, second)

    return NanoDate(datetime, Nanosecond(nanoseconds))
end

"""
    _read_char(cu::AbstractVector{UInt8}, i::Int, c::Char) -> Bool

Check if the code unit at index `i` of `cu` exists and is the ASCII character `c`.
"""
function _read_char(cu::AbstractVector{UInt8}, i::Int, c::Char)
    return (i <= length(cu)) && (cu[i] == UInt8(c))
end

"""
    _read_digits(cu::AbstractVector{UInt8}, i::Int, k::Int) -> Tuple{Int, Int}

Read exactly `k` decimal digits starting at index `i` of the code units `cu`, returning
the parsed value and the index after the digits. If the digits are not available, the
value is `-1`.
"""
function _read_digits(cu::AbstractVector{UInt8}, i::Int, k::Int)
    value = 0

    for j in i:(i + k - 1)
        j <= length(cu) || return -1, i
        c = cu[j]
        (UInt8('0') <= c <= UInt8('9')) || return -1, i
        value = 10 * value + Int(c - UInt8('0'))
    end

    return value, i + k
end

"""
    _read_fraction(cu::AbstractVector{UInt8}, i::Int) -> Tuple{Int, Int}

Read the fractional second digits starting at index `i` of the code units `cu`, returning
the value in nanoseconds and the index after the digits. Digits beyond the ninth are
consumed but ignored. If there is no digit, the value is `-1`.
"""
function _read_fraction(cu::AbstractVector{UInt8}, i::Int)
    nanoseconds = 0
    count       = 0

    while (i <= length(cu)) && (UInt8('0') <= cu[i] <= UInt8('9'))
        (count < 9) && (nanoseconds = 10 * nanoseconds + Int(cu[i] - UInt8('0')))
        count += 1
        i     += 1
    end

    count == 0 && return -1, i

    # Scale the value to nanoseconds if fewer than nine digits were read.
    while count < 9
        nanoseconds *= 10
        count       += 1
    end

    return nanoseconds, i
end
