## Description #############################################################################
#
# Functions to print the fields in the messages.
#
############################################################################################

"""
    _field_name_width(vfields::Vector{NTuple{3, String}}) -> Int

Compute the maximum width of the field names in `vfields`.
"""
function _field_name_width(vfields::Vector{NTuple{3, String}})
    max_width = 0

    for field in vfields
        w = textwidth(field[1])
        max_width = max(max_width, w)
    end

    return max_width
end

"""
    _field_value_width(vfields::Vector{NTuple{3, String}}) -> Int

Compute the maximum width of the field values in `vfields`.
"""
function _field_value_width(vfields::Vector{NTuple{3, String}})
    max_width = 0

    for field in vfields
        isempty(field[3]) && continue

        w = textwidth(field[2])
        max_width = max(max_width, w)
    end

    return max_width
end

"""
    _print_level_alignment(io::IO, level::Int, tree_level::Int; kwargs...) -> Nothing

Print to `io` the alignment for a given `level` in the tree, drawing the tree in the level
`tree_level`.

# Keywords

- `indentation::Int`: Indentation per level in spaces.
    (**Default**: 2)
- `initial_padding::Int`: Initial padding in spaces before printing the tree.
    (**Default**: 2)
"""
function _print_level_alignment(
    io::IO,
    level::Int,
    tree_level::Int;
    indentation::Int = 2,
    initial_padding::Int = 2
)
    indentation = max(2, indentation)
    level       = max(0, level)
    unit_pad    = " "^indentation
    sty_bar     = styled"{gray:│}"

    print(io, " "^initial_padding)

    if level <= tree_level
        print(io, unit_pad^level)
        return nothing
    end

    str  = unit_pad^max(0, tree_level - 1) * sty_bar
    str *= chop(unit_pad^(level - tree_level), tail = 0, head = 1)

    print(io, str)

    return nothing
end

"""
    _print_level_fields(io::IO, fields::Vector{NTuple{3, String}}, title::String, level::Int, max_level::Int, name_field_width::Int, value_field_width::Int; kwargs...) -> Nothing

Print to `io` the `fields` at the specified `level` in the tree, with the given `title`.
`max_level` is the maximum level in the tree, used to compute the indentation.
`name_field_width` and is used to align the field names properly. `value_field_width` is
used to align the values properly.

# Keywords

- `indentation::Int`: Indentation per level in spaces.
    (**Default**: `2`)
"""
function _print_level_fields(
    io::IO,
    fields::Vector{NTuple{3, String}},
    title::String,
    level::Int,
    max_level::Int,
    name_field_width::Int,
    value_field_width::Int;
    indentation::Int = 2,
    newline::Bool = true
)
    isempty(fields) && return nothing

    unit_pad = " "^indentation

    !isempty(title) && _print_level_opening(io, title * "\n", level; has_siblings = true)

    for f in fields
        _print_level_alignment(io, level, level - 1)
        print(io, unit_pad^max(0, max_level - level + 1))
        println(io, _render_field_aligned(f..., name_field_width, value_field_width))
    end

    if newline
        _print_level_alignment(io, level, level - 1)
        println(io)
    end

    return nothing
end

"""
    _print_level_opening(io::IO, name::String, level::Int; kwargs...) -> Nothing

Print to `io` the opening of a level in the tree with the given `name` at the specified
`level`.

# Keywords

- `has_siblings::Bool`: Whether the level has siblings or not.
    (**Default**: `false`)
- `indentation::Int`: Indentation per level in spaces.
    (**Default**: `2`)
- `initial_padding::Int`: Initial padding in spaces before printing the tree.
    (**Default**: `2`)
"""
function _print_level_opening(
    io::IO,
    name::String,
    level::Int;
    has_siblings::Bool = false,
    indentation::Int = 2,
    initial_padding::Int = 2,
    name_face::StyledStrings.Face = StyledStrings.Face(; foreground = :yellow, weight = :bold)
)
    sty_vbar_ns = styled"{gray:└}"
    sty_vbar_s  = styled"{gray:├}"
    sty_name    = styled"{$name_face:$name}"

    print(io, " "^initial_padding)

    if level <= 1
        print(io, sty_name)
        return nothing
    end

    indentation = max(2, indentation)
    unit_pad    = " "^indentation
    sty_hbar    = styled"{gray:$(\"─\"^(indentation - 1))}"

    str  = unit_pad^max(0, level - 2)
    str *= (has_siblings ? sty_vbar_s : sty_vbar_ns) * sty_hbar

    print(io, str * sty_name)

    return nothing
end

"""
    _push_output!(vector::Vector{NTuple{3, String}}, field::Tuple{String, Any, String}) -> Nothing

Push to `vector` the `field` if its value is not `nothing`. The field is a tuple of
`(name::String, value::Any, unit::String)`, where `value` is converted to a string.
"""
function _push_output!(vector::Vector{NTuple{3, String}}, field::Tuple{String, Any, String})
    isnothing(field[2]) && return nothing
    push!(vector, (field[1], escape_string(string(field[2])), field[3]))
    return nothing
end

"""
    _render_field_aligned(field_name::String, field_value::String, unit::String, field_name_width::Int, field_value_width::Int) -> String

Render a field with its name `field_name`, value `field_value`, and `unit` aligned according
to the specified widths for the field name `field_name_width` and field value
`field_value_width`.
"""
function _render_field_aligned(
    field_name::String,
    field_value::String,
    unit::String,
    field_name_width::Int,
    field_value_width::Int
)
    sty_unit = styled"{gray:$unit}"
    sty_name = styled"{bold:$field_name}"

    str  = lpad(sty_name, field_name_width) * " : "
    str *= unit == "°" ?
        field_value * sty_unit :
        rpad(field_value, field_value_width) * " " * sty_unit

    return str
end
