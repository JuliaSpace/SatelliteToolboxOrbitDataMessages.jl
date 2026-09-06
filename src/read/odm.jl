## Description #############################################################################
#
# Read Orbit Data Messages (ODM) from files.
#
############################################################################################

export read_odm

"""
    read_odm(file::AbstractString) -> Vector{OrbitDataMessage}
    read_odm(io::IO) -> Vector{OrbitDataMessage}

Read the Orbit Data Messages (ODM) from the provided `file` or `io` stream.

For more information, see [`parse_odm`](@ref).
"""
read_odm(file::AbstractString) = parse_odm(read(file, String))

read_odm(io::IO) = parse_odm(read(io, String))
