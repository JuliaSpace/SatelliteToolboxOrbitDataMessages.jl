## Description #############################################################################
#
# Functions to read and write KVN files.
#
############################################################################################

############################################################################################
#                                        Constants                                         #
############################################################################################

# Regular expression for parsing a KVN keyword line.
const _KVN_KEYWORD_REGEX = r"^\s*(?<keyword>[0-9A-Z_]+)\s*=\s*(?<value>.*?)\s*(?:\[(?<unit>[^\]]*)\])?\s*$"

# Regular expression for parsing a KVN comment line.
const _KVN_COMMENT_REGEX = r"^(?:\s*)?COMMENT(?:\s*)(?<comment>.*)$"

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _kvn__parse_keyword(line::AbstractString) -> Union{Nothing, Tuple{String, String}}

Parse a KVN keyword `line` and return the keyword and value as a `Tuple`, or `nothing` if
the line is not a valid keyword line.
"""
function _kvn__parse_keyword(line::AbstractString)
    # Check for `keyword = value`.
    km = match(_KVN_KEYWORD_REGEX, line)
    !isnothing(km) && return km["keyword"], km["value"]

    # Check for comments.
    cm = match(_KVN_COMMENT_REGEX, line)
    !isnothing(cm) && return "COMMENT", cm["comment"]

    return nothing
end
