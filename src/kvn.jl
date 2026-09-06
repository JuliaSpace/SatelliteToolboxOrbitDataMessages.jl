## Description #############################################################################
#
# Functions to read and write KVN files.
#
############################################################################################

############################################################################################
#                                          Types                                           #
############################################################################################

"""
    mutable struct _KvnScanner{S <: AbstractString}

Scanner that walks the lines of a KVN input without copying them.

# Fields

- `str::S`: KVN input.
- `pos::Int`: Position of the next character to be read.
- `line_start::Int`: Position of the first character of the last returned line, used to
    unread it.
- `line::Int`: Number of the last returned line (1-based).
"""
mutable struct _KvnScanner{S <: AbstractString}
    str::S
    pos::Int
    line_start::Int
    line::Int
end

"""
    _KvnScanner(str::AbstractString) -> _KvnScanner

Create a scanner positioned at the beginning of the KVN input `str`.
"""
_KvnScanner(str::AbstractString) = _KvnScanner(str, firstindex(str), firstindex(str), 0)

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _kvn__next_line!(scanner::_KvnScanner) -> Union{Nothing, SubString}

Advance `scanner` to the next non-blank line and return it without the surrounding
whitespace, or `nothing` if the input is exhausted. The returned line can be pushed back
with [`_kvn__unread_line!`](@ref).
"""
function _kvn__next_line!(scanner::_KvnScanner)
    str    = scanner.str
    i_last = lastindex(str)

    while scanner.pos <= i_last
        pos = scanner.pos
        nl  = findnext('\n', str, pos)

        line_end = isnothing(nl) ? i_last : prevind(str, nl)
        line     = strip(SubString(str, pos, line_end))

        scanner.line_start = pos
        scanner.line      += 1
        scanner.pos        = isnothing(nl) ? i_last + 1 : nextind(str, nl)

        isempty(line) || return line
    end

    return nothing
end

"""
    _kvn__unread_line!(scanner::_KvnScanner) -> Nothing

Push back the last line returned by [`_kvn__next_line!`](@ref), so that it is returned
again by the next call.
"""
function _kvn__unread_line!(scanner::_KvnScanner)
    scanner.pos   = scanner.line_start
    scanner.line -= 1
    return nothing
end

"""
    _kvn__is_keyword(str::AbstractString) -> Bool

Check if `str` follows the KVN keyword grammar: a non-empty sequence of uppercase letters,
digits, and underscores.
"""
function _kvn__is_keyword(str::AbstractString)
    isempty(str) && return false

    for c in codeunits(str)
        (UInt8('A') <= c <= UInt8('Z')) ||
            (UInt8('0') <= c <= UInt8('9')) ||
            (c == UInt8('_')) ||
            return false
    end

    return true
end

"""
    _kvn__parse_keyword(
        line::AbstractString
    ) -> Union{Nothing, Tuple{AbstractString, AbstractString}}

Parse a KVN `line`, which must not have surrounding whitespace, and return the keyword and
value as a `Tuple` of `SubString`s, or `nothing` if the line is neither a keyword nor a
comment line.

A comment line yields the synthesized keyword `"COMMENT"` with the comment text as the
value. The comment text is separated from the keyword by a single space or tab, so any
additional indentation is preserved. The value of a keyword line is returned verbatim,
including any trailing `[unit]` annotation, which can be removed with
[`_kvn__strip_unit`](@ref).
"""
function _kvn__parse_keyword(line::AbstractString)
    # Check for comments first: real files are comment-heavy, and this anchored literal
    # match is cheaper than searching for the `=` sign.
    if startswith(line, "COMMENT")
        n = ncodeunits("COMMENT")

        # A bare `COMMENT` line is a valid empty comment.
        (ncodeunits(line) == n) &&
            return SubString(line, firstindex(line), n), SubString(line, n + 1, n)

        separator = nextind(line, n)
        c         = line[separator]

        (c == ' ' || c == '\t') && return (
            SubString(line, firstindex(line), n), SubString(line, nextind(line, separator))
        )
    end

    # Check for `keyword = value`.
    i = findfirst('=', line)
    isnothing(i) && return nothing

    keyword = rstrip(SubString(line, firstindex(line), prevind(line, i)))
    _kvn__is_keyword(keyword) || return nothing

    value = strip(SubString(line, nextind(line, i)))

    return keyword, value
end

"""
    _kvn__strip_unit(value::AbstractString) -> AbstractString

Return `value` without its trailing `[unit]` annotation and the whitespace preceding it, or
`value` unchanged if it has none.

The check for the closing bracket is cheap, so the function can be called for every
non-string value regardless of the input format.
"""
function _kvn__strip_unit(value::AbstractString)
    endswith(value, ']') || return value

    i = findlast('[', value)
    isnothing(i) && return value

    return rstrip(SubString(value, firstindex(value), prevind(value, i)))
end
