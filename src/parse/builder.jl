## Description #############################################################################
#
# Builders that accumulate the raw field values of an Orbit Mean-Elements Message (OMM)
# while it is parsed.
#
# The format-specific parsers fill the builders, and the format-agnostic assembly in
# `./omm.jl` validates the mandatory fields and converts them to the message sections. The
# builders are generated from the section types so that every field is typed, avoiding the
# boxing of a `Dict{Symbol, Any}` and the dynamic keyword splat when constructing the
# sections.
#
############################################################################################

"""
    _nonnothingtype(::Type{T}) -> Type

Return `T` without `Nothing`, i.e. the wrapped type of an optional field.
"""
function _nonnothingtype(::Type{T}) where {T}
    T isa Union || return T
    return T.a === Nothing ? T.b : T.a
end

# Generate one mutable builder per section type. Each builder has the same field names as
# the section, where the mandatory scalar fields become optional (`nothing` until parsed),
# the vectors start empty, and the covariance matrix holds its own builder.
for (section, builder) in (
    OmmHeader           => :_OmmHeaderBuilder,
    OmmMetadata         => :_OmmMetadataBuilder,
    OmmCovarianceMatrix => :_OmmCovarianceMatrixBuilder,
    OmmData             => :_OmmDataBuilder,
)
    fields = map(fieldnames(section)) do field
        T = fieldtype(section, field)

        if field === :covariance_matrix
            return :($field::Union{Nothing, _OmmCovarianceMatrixBuilder} = nothing)
        elseif T <: AbstractVector
            return :($field::$T = $T())
        else
            return :($field::Union{Nothing, $(_nonnothingtype(T))} = nothing)
        end
    end

    # The scalar fields that a parser can set from a raw string value, together with the
    # branches of the generated setter and presence test.
    scalar_fields = [
        f for f in fieldnames(section) if
        (f !== :covariance_matrix) && !(fieldtype(section, f) <: AbstractVector)
    ]

    set_branches = foldr(
        (f, acc) -> :(
            if field === $(QuoteNode(f))
                b.$f = _omm_parse_field(
                    $(_nonnothingtype(fieldtype(section, f))), value, keyword
                )
            else
                $acc
            end
        ),
        scalar_fields;
        init = :(throw(ArgumentError("Unknown OMM builder field `$field`."))),
    )

    is_set_branches = foldr(
        (f, acc) -> :(field === $(QuoteNode(f)) ? !isnothing(b.$f) : $acc),
        scalar_fields;
        init = false,
    )

    # The section is built positionally from the builder fields. After the mandatory-field
    # validation, the mandatory fields are known to be set, so they are asserted to the
    # section field type.
    build_args = map(fieldnames(section)) do field
        T = fieldtype(section, field)

        if field === :covariance_matrix
            return :(
                isnothing(b.covariance_matrix) ? nothing :
                _omm_build(OmmCovarianceMatrix, b.covariance_matrix)
            )
        elseif (T <: AbstractVector) || (Nothing <: T)
            return :(b.$field)
        else
            return :(b.$field::$T)
        end
    end

    @eval begin
        @kwdef mutable struct $builder
            $(fields...)
        end

        function _omm_set_field!(
            b::$builder, field::Symbol, value::AbstractString, keyword::AbstractString
        )
            $set_branches
            return nothing
        end

        _omm_field_is_set(b::$builder, field::Symbol) = $is_set_branches

        _omm_build(::Type{$section}, b::$builder) = $section($(build_args...))
    end
end

"""
    mutable struct _OmmBuilder

Builder with the raw field values of an Orbit Mean-Elements Message (OMM), filled by the
format-specific parsers and assembled into the message by [`_omm_assemble`](@ref).

# Fields

- `version::Union{Nothing, Float64}`: OMM format version, or `nothing` if it is absent in
    the input.
- `header::_OmmHeaderBuilder`: Raw field values of the header section.
- `metadata::_OmmMetadataBuilder`: Raw field values of the metadata section.
- `data::_OmmDataBuilder`: Raw field values of the data section.
"""
mutable struct _OmmBuilder
    version::Union{Nothing, Float64}
    header::_OmmHeaderBuilder
    metadata::_OmmMetadataBuilder
    data::_OmmDataBuilder
end

"""
    _OmmBuilder() -> _OmmBuilder

Create an empty builder without a version.
"""
function _OmmBuilder()
    return _OmmBuilder(
        nothing, _OmmHeaderBuilder(), _OmmMetadataBuilder(), _OmmDataBuilder()
    )
end

"""
    _omm_set_field!(
        b::Union{
            _OmmHeaderBuilder,
            _OmmMetadataBuilder,
            _OmmDataBuilder,
            _OmmCovarianceMatrixBuilder,
        },
        field::Symbol,
        value::AbstractString,
        keyword::AbstractString
    ) -> Nothing

Parse the raw `value` of the CCSDS `keyword` with the type of the builder `field` and store
it in `b`. The methods are generated for every section builder, so the conversion is
resolved statically from the field name.
"""
_omm_set_field!

"""
    _omm_field_is_set(
        b::Union{
            _OmmHeaderBuilder,
            _OmmMetadataBuilder,
            _OmmDataBuilder,
            _OmmCovarianceMatrixBuilder,
        },
        field::Symbol
    ) -> Bool

Check if the scalar `field` of the builder `b` was already set.
"""
_omm_field_is_set

"""
    _omm_build(::Type{T}, b) -> T

Build the section of type `T` from the builder `b`. The mandatory fields must have been
validated beforehand.
"""
_omm_build
