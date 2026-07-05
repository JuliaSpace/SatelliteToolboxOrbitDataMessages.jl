## Description #############################################################################
#
# Read Orbit Mean-Elements Messages (OMM) from files.
#
############################################################################################

export read_omm

"""
    read_omm(file::AbstractString) -> Union{Nothing, OrbitMeanElementsMessage}

Read an Orbit Mean-Elements Message (OMM) from the provided `file`.

    read_omm(io::IO) -> Union{Nothing, OrbitMeanElementsMessage}

Read an Orbit Mean-Elements Message (OMM) from the provided `io` stream.
"""
function read_omm(file::AbstractString)
    # Open the file and parse the OMM.
    open(file, "r") do io
        str = read(io, String)
        return parse_omm(str)
    end
end

function read_omm(io::IO)
    str = read(io, String)
    return parse_omm(str)
end
