## Description #############################################################################
#
# Parse Orbit Data Messages (ODM) using KVN input.
#
############################################################################################

# Version keywords that start each ODM message type in the KVN format, in the order of
# `_XML_ODM__TAGS`.
const _KVN_ODM__VERSION_KEYWORDS = (
    "CCSDS_OMM_VERS",
    "CCSDS_OPM_VERS",
    "CCSDS_OEM_VERS",
    "CCSDS_OCM_VERS",
)

"""
    _kvn_odm__message_index(keyword::AbstractString) -> Union{Nothing, Int}

Return the index in `_KVN_ODM__VERSION_KEYWORDS` (and `_XML_ODM__TAGS`) of the ODM message
type started by `keyword`, or `nothing` if `keyword` is not a version keyword.
"""
function _kvn_odm__message_index(keyword::AbstractString)
    return findfirst(==(keyword), _KVN_ODM__VERSION_KEYWORDS)
end

"""
    _kvn_odm__parse(str::AbstractString) -> Vector{OrbitDataMessage}

Parse the Orbit Data Messages (ODM) in the KVN input `str`, returning a vector with the
parsed messages.

There is no standard container for multiple KVN messages, so each message is assumed to
start at its version keyword (e.g. `CCSDS_OMM_VERS`) and to end right before the next one.
Any content before the first version keyword is ignored. Unsupported message types (OPM,
OEM, OCM) are skipped with a warning.
"""
function _kvn_odm__parse(str::AbstractString)
    scanner  = _KvnScanner(str)
    messages = OrbitDataMessage[]

    while true
        line = _kvn__next_line!(scanner)
        isnothing(line) && break

        km = _kvn__parse_keyword(line)
        isnothing(km) && continue

        i = _kvn_odm__message_index(km[1])
        isnothing(i) && continue

        # The message parsers expect the scanner positioned before the version line.
        _kvn__unread_line!(scanner)

        message = _kvn_odm__parse_message(Val(Symbol(_XML_ODM__TAGS[i])), scanner)
        isnothing(message) || push!(messages, message)
    end

    return messages
end

"""
    _kvn_odm__parse_message(
        ::Val{tag},
        scanner::_KvnScanner
    ) -> Union{Nothing, OrbitDataMessage}

Parse the ODM message of type `tag` starting at the next line of `scanner`, dispatching on
`Val(tag)`, and return the parsed message. Message types that are not supported yet emit a
warning, skip their lines, and return `nothing`.

To add support for a new message type, define a method for the corresponding tag, e.g.
`_kvn_odm__parse_message(::Val{:opm}, scanner::_KvnScanner)`, returning the assembled
message.
"""
function _kvn_odm__parse_message(::Val{:omm}, scanner::_KvnScanner)
    return _omm_assemble(_kvn_omm__parse!(scanner))
end

for (tag, name) in (
    :opm => "Orbit Parameter Messages (OPM)",
    :oem => "Orbit Ephemeris Messages (OEM)",
    :ocm => "Orbit Comprehensive Messages (OCM)",
)
    @eval function _kvn_odm__parse_message(::Val{$(QuoteNode(tag))}, scanner::_KvnScanner)
        @warn $("We do not support $name yet.")
        _kvn_odm__skip_message!(scanner)
        return nothing
    end
end

"""
    _kvn_odm__skip_message!(scanner::_KvnScanner) -> Nothing

Skip the message starting at the next line of `scanner`, leaving the scanner positioned
before the version line of the next message, if any.
"""
function _kvn_odm__skip_message!(scanner::_KvnScanner)
    # Consume the version line of the skipped message.
    _kvn__next_line!(scanner)

    while true
        line = _kvn__next_line!(scanner)
        isnothing(line) && return nothing

        km = _kvn__parse_keyword(line)
        (isnothing(km) || isnothing(_kvn_odm__message_index(km[1]))) && continue

        _kvn__unread_line!(scanner)
        return nothing
    end
end
