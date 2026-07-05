
## Description #############################################################################
#
# Read Orbit Data Messages (ODM) from files.
#
############################################################################################

export read_odm

"""
    read_odm(file::AbstractString) -> Union{Nothing, Vector{OrbitDataMessage}}

Read an Orbit Data Message (ODM) from the provided `file`.

    read_odm(io::IO) -> Union{Nothing, Vector{OrbitDataMessage}}

Read an Orbit Data Message (ODM) from the provided `io` stream.
"""
function read_odm(file::AbstractString)
    # Open the file and parse the ODM.
    open(file, "r") do io
        str = read(io, String)
        return parse_odm(str)
    end
end

function read_odm(io::IO)
    str = read(io, String)
    return parse_odm(str)
end
