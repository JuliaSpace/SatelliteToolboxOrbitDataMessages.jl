## Description #############################################################################
#
# Definition of types and constructors for Orbit Data Messages (ODM).
#
## References ##############################################################################
#
# [1] CCSDS 502.0-B-3 (2023). Orbit Data Messages. CCSDS Secretariat, Issue 3. Washington,
#     DC, USA.
#
############################################################################################

export OrbitDataMessage, OdmParseError

"""
    abstract type OrbitDataMessage

Supertype of all Orbit Data Messages (ODM) defined by the CCSDS 502.0-B-3 standard.

Every concrete message type supported by this package (for example,
[`OrbitMeanElementsMessage`](@ref)) is a subtype of `OrbitDataMessage`. Functions that
handle generic messages, such as [`parse_odm`](@ref) and [`write_odm`](@ref), operate on
this abstract type.
"""
abstract type OrbitDataMessage end

"""
    struct OdmParseError <: Exception

Exception thrown when an Orbit Data Message cannot be parsed because the input is malformed
or violates the CCSDS 502.0-B-3 rules (e.g. a missing mandatory field or an unknown tag).

# Fields

- `msg::String`: Description of the problem.
- `keyword::Union{String, Nothing}`: CCSDS keyword or XML tag related to the problem, if
    any.
- `line::Union{Int, Nothing}`: Line of the input where the problem was found, if known
    (KVN input only).
"""
struct OdmParseError <: Exception
    msg::String
    keyword::Union{String, Nothing}
    line::Union{Int, Nothing}
end

"""
    OdmParseError(msg::String; kwargs...) -> OdmParseError

Create an [`OdmParseError`](@ref) with the description `msg`.

# Keywords

- `keyword::Union{AbstractString, Nothing}`: CCSDS keyword or XML tag related to the
    problem, if any.
    (**Default**: `nothing`)
- `line::Union{Int, Nothing}`: Line of the input where the problem was found, if known.
    (**Default**: `nothing`)
"""
function OdmParseError(
    msg::String;
    keyword::Union{AbstractString, Nothing} = nothing,
    line::Union{Int, Nothing} = nothing,
)
    return OdmParseError(msg, isnothing(keyword) ? nothing : String(keyword), line)
end

function Base.showerror(io::IO, e::OdmParseError)
    print(io, "OdmParseError: ", e.msg)
    isnothing(e.line) || print(io, " (line ", e.line, ")")
    return nothing
end
