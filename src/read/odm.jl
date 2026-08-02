## Description #############################################################################
#
# Read Orbit Data Messages (ODM) from files.
#
############################################################################################

export read_odm

"""
    read_odm(file::AbstractString; kwargs...) -> Vector{OrbitDataMessage}

Read an Orbit Data Message (ODM) from the provided `file`.

    read_odm(io::IO; kwargs...) -> Vector{OrbitDataMessage}

Read an Orbit Data Message (ODM) from the provided `io` stream.

# Keywords

- `strict::Bool`: Require schema-defined XML tag casing. If `false`, match tags and the OMM
    `id` attribute value case-insensitively.
    (**Default**: `true`)
"""
function read_odm(file::AbstractString; strict::Bool = true)
    # Read the file and parse the ODM.
    str = read(file, String)
    return parse_odm(str; strict)
end

function read_odm(io::IO; strict::Bool = true)
    str = read(io, String)
    return parse_odm(str; strict)
end
