## Description #############################################################################
#
# Read Orbit Mean-Elements Messages (OMM) from files.
#
############################################################################################

export read_omm, read_omms

"""
    read_omm(file::AbstractString; kwargs...) -> OrbitMeanElementsMessage
    read_omm(io::IO; kwargs...) -> OrbitMeanElementsMessage

Read an Orbit Mean-Elements Message (OMM) from the provided `file` or `io` stream.

If the input contains multiple messages, only the first OMM is returned. If it does not
contain an OMM, an [`OdmParseError`](@ref) is thrown. For more information, see
[`parse_omm`](@ref).

# Keywords

- `file_type::Symbol`: The input file type. If `:auto`, the file type is inferred from the
    content. It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
"""
read_omm(file::AbstractString; kwargs...) = parse_omm(read(file, String); kwargs...)

read_omm(io::IO; kwargs...) = parse_omm(read(io, String); kwargs...)

"""
    read_omms(file::AbstractString; kwargs...) -> Vector{OrbitMeanElementsMessage}
    read_omms(io::IO; kwargs...) -> Vector{OrbitMeanElementsMessage}

Read a set of Orbit Mean-Elements Messages (OMM) from the provided `file` or `io` stream.

If the input contains messages of other types, only the OMMs are returned. If it does not
contain an OMM, an empty vector is returned. For more information, see
[`parse_omms`](@ref).

# Keywords

- `file_type::Symbol`: The input file type. If `:auto`, the file type is inferred from the
    content. It can be `:auto`, `:kvn`, or `:xml`.
    (**Default**: `:auto`)
"""
read_omms(file::AbstractString; kwargs...) = parse_omms(read(file, String); kwargs...)

read_omms(io::IO; kwargs...) = parse_omms(read(io, String); kwargs...)
