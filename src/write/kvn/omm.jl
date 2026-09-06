## Description #############################################################################
#
# Write Orbit Mean-Elements Messages (OMM) using KVN output.
#
############################################################################################

############################################################################################
#                                        Constants                                         #
############################################################################################

# Width of the longest standard OMM keyword ("MEAN_ELEMENT_THEORY" and
# "CLASSIFICATION_TYPE"), used as the minimum width of the keyword column.
const _KVN_OMM__MINIMUM_KEYWORD_WIDTH = 19

# Width of the value column when a unit is appended, aligning the units of consecutive
# fields.
const _KVN_OMM__VALUE_WIDTH = 15

# Prefix prepended to the user-defined parameter names, matching the prefix stripped by
# the KVN parser, and its width in the keyword column.
const _KVN_OMM__USER_DEFINED_PREFIX = "USER_DEFINED_"
const _KVN_OMM__USER_DEFINED_PREFIX_WIDTH = textwidth(_KVN_OMM__USER_DEFINED_PREFIX)

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _kvn_omm__write(io::IO, omm::OrbitMeanElementsMessage) -> Nothing
    _kvn_omm__write(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage}) -> Nothing

Write the given `omm` (or the set of messages in `vomm`) to the provided `io` stream in
KVN format. A set of messages is written sequentially, delimited by their
`CCSDS_OMM_VERS` keywords as expected by [`parse_omms`](@ref).

The written version is always `3.0`, regardless of the version stored in the messages,
matching the behavior of the XML writer.

!!! note

    The KVN format is flat, so the comments of the data section (`omm.data.comments`) are
    written immediately before the mean-elements fields. Hence, they are attributed to the
    mean-elements section if the output is parsed back. Additionally, the comments of a
    section whose fields are all `nothing` are dropped with a warning (see
    [`_kvn_omm__write_section`](@ref)).
"""
function _kvn_omm__write(io::IO, omm::OrbitMeanElementsMessage)
    data = omm.data

    # Compute the width of the keyword column. The user-defined parameter names can be
    # longer than every standard keyword, so we take them into account here.
    user_defined_keyword_width = maximum(
        p -> textwidth(first(p)) + _KVN_OMM__USER_DEFINED_PREFIX_WIDTH,
        data.user_defined_parameters;
        init = 0,
    )

    keyword_width = max(_KVN_OMM__MINIMUM_KEYWORD_WIDTH, user_defined_keyword_width)

    # == Version ===========================================================================

    _kvn_omm__write_element(io, "CCSDS_OMM_VERS", "3.0", keyword_width)
    println(io)

    # == Header ============================================================================

    _kvn_omm__write_section(
        io,
        omm.header,
        _OMM_HEADER_KEYWORD_TO_FIELD,
        omm.header.comments,
        keyword_width,
        "header",
    ) && println(io)

    # == Metadata ==========================================================================

    _kvn_omm__write_section(
        io,
        omm.metadata,
        _OMM_METADATA_KEYWORD_TO_FIELD,
        omm.metadata.comments,
        keyword_width,
        "metadata",
    ) && println(io)

    # == Data ==============================================================================

    # The KVN format has no data-level comment placement, so the comments of the data
    # section are written immediately before the mean-elements fields.
    for comment in data.comments
        println(io, "COMMENT ", comment)
    end

    # -- Mean Keplerian Elements -----------------------------------------------------------

    _kvn_omm__write_section(
        io,
        data,
        _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD,
        data.mean_elements_comments,
        keyword_width,
        "mean elements",
    ) && println(io)

    # -- Spacecraft Parameters -------------------------------------------------------------

    _kvn_omm__write_section(
        io,
        data,
        _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
        data.spacecraft_parameters_comments,
        keyword_width,
        "spacecraft parameters",
    ) && println(io)

    # -- TLE Related Parameters ------------------------------------------------------------

    _kvn_omm__write_section(
        io,
        data,
        _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD,
        data.tle_parameters_comments,
        keyword_width,
        "TLE parameters",
    ) && println(io)

    # -- Covariance Matrix -----------------------------------------------------------------

    if !isnothing(data.covariance_matrix)
        covariance_matrix = data.covariance_matrix

        _kvn_omm__write_section(
            io,
            covariance_matrix,
            _OMM_COVARIANCE_KEYWORD_TO_FIELD,
            covariance_matrix.comments,
            keyword_width,
            "covariance matrix",
        ) && println(io)
    end

    # -- User-Defined Parameters -----------------------------------------------------------

    for (key, value) in data.user_defined_parameters
        _kvn_omm__write_element(
            io, _KVN_OMM__USER_DEFINED_PREFIX * key, value, keyword_width
        )
    end

    return nothing
end

function _kvn_omm__write(io::IO, vomm::AbstractVector{OrbitMeanElementsMessage})
    for omm in vomm
        _kvn_omm__write(io, omm)
    end

    return nothing
end

"""
    _kvn_omm__check_user_defined_keys(omm::OrbitMeanElementsMessage) -> Nothing

Check if every user-defined parameter name in `omm` matches the KVN keyword grammar
(uppercase letters, digits, and underscores), throwing an `ArgumentError` otherwise. Any
other name would produce a KVN output that cannot be parsed back.
"""
function _kvn_omm__check_user_defined_keys(omm::OrbitMeanElementsMessage)
    for (key, _) in omm.data.user_defined_parameters
        _kvn__is_keyword(key) || throw(
            ArgumentError(
                "The user-defined parameter name \"$key\" cannot be written in the KVN " *
                "format, whose keywords only accept uppercase letters, digits, and " *
                "underscores.",
            ),
        )
    end

    return nothing
end

"""
    _kvn_omm__write_section(
        io::IO,
        section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
        mapping::Vector{Pair{String, Symbol}},
        comments::Vector{String},
        keyword_width::Int,
        section_name::String
    ) -> Bool

Write the fields of the OMM `section` to the provided `io` stream in KVN format. The
written keywords and their fields are given by `mapping`, whose order is preserved in the
output, and the section `comments` are written before the fields. The keywords are padded
to `keyword_width` characters to align the values, and `section_name` names the section in
warnings.

Fields whose value is `nothing` are omitted from the output. If every field is `nothing`,
the section comments are dropped with a warning: the flat KVN format has no section
delimiters, so the parser would attribute such comments to the next section.

# Returns

- `Bool`: `true` if any line was written, `false` otherwise.
"""
function _kvn_omm__write_section(
    io::IO,
    section::Union{OmmHeader, OmmMetadata, OmmData, OmmCovarianceMatrix},
    mapping::Vector{Pair{String, Symbol}},
    comments::Vector{String},
    keyword_width::Int,
    section_name::String,
)
    # A comments-only section cannot be represented in the flat KVN format: the parser
    # would attribute its comments to the next section. Hence, the comments are dropped
    # with a warning.
    if all(p -> isnothing(getfield(section, last(p))), mapping)
        isempty(comments) ||
            @warn "Dropping the comments of the $section_name section, which has no " *
                "fields and cannot be represented in the KVN output."
        return false
    end

    written = false

    # Write the section comments first, matching the layout expected by the KVN parser.
    for comment in comments
        println(io, "COMMENT ", comment)
        written = true
    end

    # Write the section fields in the order defined by the mapping.
    for (keyword, field) in mapping
        value = getfield(section, field)
        isnothing(value) && continue

        _kvn_omm__write_element(io, keyword, value, keyword_width, _omm_field_unit(field))
        written = true
    end

    return written
end

"""
    _kvn_omm__write_element(
        io::IO,
        keyword::AbstractString,
        value::Any,
        keyword_width::Int,
        unit::Union{Nothing, String} = nothing
    ) -> Nothing

Write the line `keyword = value` to the provided `io` stream in KVN format. The `keyword`
is padded to `keyword_width` characters to align the values, and the `value` is rendered
with [`_ndm_render_value`](@ref). If a `unit` is provided, it is appended in square
brackets, padding the value to `_KVN_OMM__VALUE_WIDTH` characters to align the units.
"""
function _kvn_omm__write_element(
    io::IO,
    keyword::AbstractString,
    value::Any,
    keyword_width::Int,
    unit::Union{Nothing, String} = nothing,
)
    rendered_value = _ndm_render_value(value)

    if isnothing(unit)
        println(io, rpad(keyword, keyword_width), " = ", rendered_value)
    else
        println(
            io,
            rpad(keyword, keyword_width),
            " = ",
            rpad(rendered_value, _KVN_OMM__VALUE_WIDTH),
            " [",
            unit,
            "]",
        )
    end

    return nothing
end
