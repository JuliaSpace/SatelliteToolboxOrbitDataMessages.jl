## Description #############################################################################
#
# Parse a set of Orbit Mean-Elements Messages (OMM) using KVN input.
#
############################################################################################

"""
    _kvn_omms__parse(str::AbstractString, strict::Bool) -> Vector{OrbitMeanElementsMessage}

Parse a set of Orbit Mean-Elements Messages (OMM) in the KVN input `str` and return the
parsed messages. The `strict` flag selects whether the mandatory fields are validated
strictly (see [`_omm_check_mandatory_fields`](@ref)).
"""
function _kvn_omms__parse(str::AbstractString, strict::Bool)
    # There is no standard for KVN OMMs, so we will assume that each OMM is delimited by the
    # `CCSDS_OMM_VERS` keyword. The input is sliced into one `SubString` chunk per message,
    # avoiding any copy of the line contents. Content before the first `CCSDS_OMM_VERS` line
    # (e.g. blank lines or comments) is ignored.
    omms = OrbitMeanElementsMessage[]

    i_last      = lastindex(str)
    chunk_start = nothing
    pos         = firstindex(str)

    while pos <= i_last
        nl       = findnext('\n', str, pos)
        line_end = isnothing(nl) ? i_last : prevind(str, nl)
        line     = SubString(str, pos, line_end)

        km = _kvn__parse_keyword(line)

        if !isnothing(km) && (km[1] == "CCSDS_OMM_VERS")
            # If we have already started an OMM, we need to parse it before starting the new
            # one.
            if !isnothing(chunk_start)
                chunk = SubString(str, chunk_start, prevind(str, pos))
                push!(omms, parse_omm(chunk; file_type = :kvn, strict))
            end

            chunk_start = pos
        end

        pos = isnothing(nl) ? i_last + 1 : nextind(str, nl)
    end

    # Parse the last OMM in the input, if any.
    if !isnothing(chunk_start)
        chunk = SubString(str, chunk_start, i_last)
        push!(omms, parse_omm(chunk; file_type = :kvn, strict))
    end

    return omms
end
