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

- `format::Symbol`: The input format. If `:auto`, the format is inferred from the content.
    It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
"""
read_odm(file::AbstractString; kwargs...) = parse_odm(read(file, String); kwargs...)

read_odm(io::IO; kwargs...) = parse_odm(read(io, String); kwargs...)
