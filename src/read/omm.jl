## Description #############################################################################
#
# Read Orbit Mean-Elements Messages (OMM) from files.
#
############################################################################################

export read_omm

"""
    read_omm(file::AbstractString; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Read an Orbit Mean-Elements Message (OMM) from the provided `file`.

    read_omm(io::IO; kwargs...) -> Union{Nothing, OrbitMeanElementsMessage}

Read an Orbit Mean-Elements Message (OMM) from the provided `io` stream.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing.
    (**Default**: `true`)
"""
function read_omm(file::AbstractString; strict::Bool = true)
    # Open the file and parse the OMM.
    open(file, "r") do io
        str = read(io, String)
        return parse_omm(str; strict)
    end
end

function read_omm(io::IO; strict::Bool = true)
    str = read(io, String)
    return parse_omm(str; strict)
end
