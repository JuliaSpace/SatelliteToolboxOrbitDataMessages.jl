## Description #############################################################################
#
# Read Orbit Data Messages (ODM) from files.
#
############################################################################################

export read_odm

"""
    read_odm(file::AbstractString; kwargs...) -> Vector{OrbitDataMessage}
    read_odm(io::IO; kwargs...) -> Vector{OrbitDataMessage}

Read the Orbit Data Messages (ODM) from the provided `file` or `io` stream.

For more information, see [`parse_odm`](@ref).

# Keywords

- `strict::Bool`: Select the validation strictness. For more information, see
    [`parse_odm`](@ref).
    (**Default**: `true`)
"""
function read_odm(file::AbstractString; strict::Bool = true)
    # Read the file and parse the ODM.
    return parse_odm(read(file, String); strict)
end

function read_odm(io::IO; strict::Bool = true)
    str = read(io, String)
    return parse_odm(str; strict)
end
