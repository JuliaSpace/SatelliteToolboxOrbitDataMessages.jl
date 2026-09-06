## Description #############################################################################
#
# Functions to read and write KVN files.
#
############################################################################################

############################################################################################
#                                        Constants                                         #
############################################################################################

# Regular expression for parsing a KVN keyword line.
const _KVN_KEYWORD_REGEX = r"^\s*(?<keyword>[0-9A-Z_]+)\s*=\s*(?<value>.*?)\s*$"

# Regular expression for parsing a KVN comment line. The comment text is separated from the
# `COMMENT` keyword by a single space or tab, so any additional indentation is preserved.
const _KVN_COMMENT_REGEX = r"^\s*(?<keyword>COMMENT)(?:[ \t](?<comment>.*))?$"

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _kvn__parse_keyword(
        line::AbstractString
    ) -> Union{Nothing, Tuple{AbstractString, AbstractString}}

Parse a KVN `line` and return the keyword and value as a `Tuple` of `SubString`s, or
`nothing` if the line is neither a keyword nor a comment line.

A comment line yields the synthesized keyword `"COMMENT"` with the comment text as the
value. The value of a keyword line is returned verbatim, including any trailing `[unit]`
annotation, which can be removed with [`_kvn__strip_unit`](@ref).
"""
function _kvn__parse_keyword(line::AbstractString)
    # Check for comments first: real files are comment-heavy, and this anchored literal
    # match is cheaper than the keyword regex.
    cm = match(_KVN_COMMENT_REGEX, line)
    !isnothing(cm) && return cm[1], something(cm[2], SubString(line, 1, 0))

    # Check for `keyword = value`.
    km = match(_KVN_KEYWORD_REGEX, line)
    !isnothing(km) && return km[1], km[2]

    return nothing
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
