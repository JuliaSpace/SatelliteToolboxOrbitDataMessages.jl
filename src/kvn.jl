## Description #############################################################################
#
# Functions to read and write KVN files.
#
############################################################################################

const _KVN_KEYWORD_REGEX = r"^(?:\s*)?(?<keyword>[0-9A-Z_]*)(?:\s*)?=(?:\s*)(?<value>[^\s]*)(?:\s*)\[(?<unit>[^\]]*)\](?:\s*)$"
const _KVN_COMMENT_REGEX = r"^(?:\s*)?COMMENT(?:\s*)(?<comment>.*)$"

function _kvn__keyword_to_symbol(keyword::AbstractString)
    # Convert a KVN keyword to a symbol.
    return Symbol(lowercase(keyword))
end

function _kvn__parse_keyword(line::AbstractString)
    # Check for `keyword = value`.
    km = match(_KVN_KEYWORD_REGEX, line)
    !isnothing(km) && return _kvn__keyword_to_symbol(km["keyword"]), km["value"]

    # Check for comments.
    cm = match(_KVN_COMMENT_REGEX, line)
    !isnothing(cm) && return :comment, cm["comment"]

    return :invalid, ""
end

function _kvn__parse_value(::Val{:integer}, value::AbstractString)
    # Parse an integer value.
    return tryparse(Int, value)
end

function _kvn__parse_value(::Val{:datetime}, value::AbstractString)
    return _parse_ndm_date(value)
end

function _kvn__parse_value(::Val{:string}, value::AbstractString)
    return value
end

function _kvn__parse_value(::Val{:float}, value::AbstractString)
    return tryparse(Float64, value)
end
