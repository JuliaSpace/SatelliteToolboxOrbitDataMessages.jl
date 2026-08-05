## Description #############################################################################
#
# Functions to print the fields in the messages.
#
############################################################################################

"""
    _register_faces() -> Nothing

Register the named `StyledStrings` faces used to render the orbit data messages. This
function is idempotent: faces already registered are not overwritten.

The registered faces are:

- `:satellitetoolbox_odm_title`: Structure name (e.g., `OrbitMeanElementsMessage:`).
- `:satellitetoolbox_odm_section`: Top-level sections (`Header`, `Metadata`, and `Data`).
- `:satellitetoolbox_odm_node`: Tree nodes (the data subsection titles).
- `:satellitetoolbox_odm_tree`: Tree rails and connectors.
- `:satellitetoolbox_odm_field`: Field names.
- `:satellitetoolbox_odm_unit`: Field units.
"""
function _register_faces()
    faces = (
        :satellitetoolbox_odm_title => StyledStrings.Face(; weight = :bold),
        :satellitetoolbox_odm_section =>
            StyledStrings.Face(; foreground = :magenta, weight = :bold),
        :satellitetoolbox_odm_node =>
            StyledStrings.Face(; foreground = :yellow, weight = :bold),
        :satellitetoolbox_odm_tree  => StyledStrings.Face(; foreground = :gray),
        :satellitetoolbox_odm_field => StyledStrings.Face(; weight = :bold),
        :satellitetoolbox_odm_unit  => StyledStrings.Face(; foreground = :gray),
    )

    # `addface!` does not overwrite a face that is already registered, so this call is
    # idempotent and preserves user customizations.
    foreach(StyledStrings.addface!, faces)

    return nothing
end

"""
    _format_value(value) -> String

Convert `value` to its display `String`. This function is the single formatting seam for
field values, allowing consistent formatting across every message.

The default method uses `string`, which for `AbstractFloat` yields the shortest
representation that round-trips exactly (e.g., `7134.084`, `4.47e-6`), avoiding any loss of
precision in the orbital elements.
"""
_format_value(value) = string(value)

"""
    _field_name_width(fields::AbstractVector{NTuple{3, String}}) -> Int

Compute the maximum width of the field names in `fields`.
"""
_field_name_width(fields::AbstractVector{NTuple{3, String}}) =
    maximum(f -> textwidth(f[1]), fields; init = 0)

"""
    _push_output!(
        vector::AbstractVector{NTuple{3, String}},
        name::String,
        value::Any,
        unit::String
    ) -> Nothing

Push to `vector` the field row `(name, value, unit)` if `value` is not `nothing`. The
`value` is converted to a string using [`_format_value`](@ref).

Passing the row components as positional arguments lets the compiler specialize on the
value type, avoiding the tuple conversion and boxing of a `Tuple{String, Any, String}`
argument.
"""
function _push_output!(
    vector::AbstractVector{NTuple{3, String}}, name::String, value::Any, unit::String
)
    isnothing(value) && return nothing
    push!(vector, (name, escape_string(_format_value(value)), unit))
    return nothing
end

"""
    _render_field(
        field_name::String,
        field_value::String,
        unit::String,
        name_width::Int
    ) -> AbstractString

Render a single field row `<name> : <value> <unit>`, left-aligning `field_name` to
`name_width`. The `unit` is appended inline separated by a space, except for the degree unit
`"°"`, which hugs the value. The returned string has no trailing whitespace.
"""
function _render_field(
    field_name::String, field_value::String, unit::String, name_width::Int
)
    sty_name = styled"{satellitetoolbox_odm_field:$field_name}"

    # The row is built with a manual padding and string concatenation using `*`, which
    # preserves styling annotations on all supported Julia versions (`annotatedstring` was
    # only introduced in Julia 1.11).
    padding = " "^max(0, name_width - textwidth(field_name))

    if isempty(unit)
        return rstrip(*(sty_name, padding, " : ", field_value))
    end

    sty_unit  = styled"{satellitetoolbox_odm_unit:$unit}"
    separator = unit == "°" ? "" : " "

    return rstrip(*(sty_name, padding, " : ", field_value, separator, sty_unit))
end

"""
    _print_node(
        io::IO,
        name::String,
        rail::String,
        connector::String,
        face::Symbol
    ) -> Nothing

Print to `io` a tree node opening with the given `name` styled with `face`, preceded by
`rail` (the ancestor tree rails) and `connector` (e.g., `"├─ "`, `"└─ "`, or `""` for a
top-level heading).
"""
function _print_node(io::IO, name::String, rail::String, connector::String, face::Symbol)
    sty_conn = styled"{satellitetoolbox_odm_tree:$connector}"
    sty_name = styled"{$face:$name}"
    println(io, styled"{satellitetoolbox_odm_tree:$rail}", sty_conn, sty_name)
    return nothing
end

"""
    _print_fields(
        io::IO,
        fields::AbstractVector{NTuple{3, String}},
        rail::String
    ) -> Nothing

Print to `io` the `fields`, each preceded by `rail` (the tree rails drawn before the field
name). The field names are left-aligned to the widest name in `fields`.
"""
function _print_fields(io::IO, fields::AbstractVector{NTuple{3, String}}, rail::String)
    isempty(fields) && return nothing

    name_width = _field_name_width(fields)
    sty_rail   = styled"{satellitetoolbox_odm_tree:$rail}"

    for f in fields
        println(io, sty_rail, _render_field(f..., name_width))
    end

    return nothing
end
