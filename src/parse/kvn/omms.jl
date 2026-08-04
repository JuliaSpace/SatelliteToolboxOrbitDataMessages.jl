## Description #############################################################################
#
# Parse a set of Orbit Mean-Elements Messages (OMM) using KVN input.
#
############################################################################################

"""
    _kvn_omms__parse(str::String) -> OrbitMeanElementsMessage

Parse a set of Orbit Mean-Elements Message (OMM) in the KVN input `str` and return the
parsed message.
"""
function _kvn_omms__parse(str::String)
    # There is no standard for KVN OMMs, so we will assume that each OMM is separated by the
    # `CCSDS_OMM_VERS` keyword.
    current_file = IOBuffer()

    omms = OrbitMeanElementsMessage[]

    for line in eachsplit(str, '\n')
        if startswith(line, "CCSDS_OMM_VERS")
            # If we have already started a new OMM, we need to parse the previous one.
            if position(current_file) > 0
                seekstart(current_file)
                omm = parse_omm(String(take!(current_file)); file_type = :kvn)
                push!(omms, omm)
            end
        end
        write(current_file, line * "\n")
    end

    return omms
end
