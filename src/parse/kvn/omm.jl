## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using KVN input.
#
############################################################################################

# All the OMM keywords merged into a single mapping from the CCSDS keyword to the section
# index and the corresponding builder field. The section index refers to the section order
# of the flat KVN format: 1) header, 2) metadata, 3) mean elements, 4) spacecraft
# parameters, 5) TLE parameters, and 6) covariance matrix. The per-section mappings in
# `../omm.jl` are required by formats with a nested structure (e.g. XML), whereas the flat
# KVN format resolves any keyword with a single lookup in this merged mapping.
const _KVN_OMM__KEYWORD_TO_SECTION_AND_FIELD = Dict{String, Tuple{Int, Symbol}}(
    (k => (1, f) for (k, f) in _OMM_HEADER_KEYWORD_TO_FIELD)...,
    (k => (2, f) for (k, f) in _OMM_METADATA_KEYWORD_TO_FIELD)...,
    (k => (3, f) for (k, f) in _OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD)...,
    (k => (4, f) for (k, f) in _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD)...,
    (k => (5, f) for (k, f) in _OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD)...,
    (k => (6, f) for (k, f) in _OMM_COVARIANCE_KEYWORD_TO_FIELD)...,
)

"""
    _kvn_omm__parse(str::AbstractString) -> _OmmBuilder

Parse the first Orbit Mean-Elements Message (OMM) in the KVN input `str`, returning the
builder with the raw field values. The version and the mandatory fields are checked
afterwards by [`_omm_assemble`](@ref).

The message starts at the first `CCSDS_OMM_VERS` keyword, and any content before it is
ignored. An `OdmParseError` is thrown if the input does not contain an OMM.
"""
function _kvn_omm__parse(str::AbstractString)
    scanner = _KvnScanner(str)

    while true
        line = _kvn__next_line!(scanner)
        isnothing(line) && break

        km = _kvn__parse_keyword(line)
        (isnothing(km) || (km[1] != "CCSDS_OMM_VERS")) && continue

        _kvn__unread_line!(scanner)
        return _kvn_omm__parse!(scanner)
    end

    throw(OdmParseError("The KVN input does not contain an OMM."))
end

"""
    _kvn_omm__parse!(scanner::_KvnScanner) -> _OmmBuilder

Parse the Orbit Mean-Elements Message (OMM) starting at the next line of `scanner`, which
must be its `CCSDS_OMM_VERS` keyword, returning the builder with the raw field values. The
message ends at the input end or right before the next version keyword (see
`_KVN_ODM__VERSION_KEYWORDS`), which is left in the scanner for the next message parser.
"""
function _kvn_omm__parse!(scanner::_KvnScanner)
    builder = _OmmBuilder()

    # Comments precede the content of the section they refer to in KVN files. Hence, we
    # buffer consecutive comment lines and assign them to the section of the next recognized
    # keyword. Comments at the end of the message are assigned to the section of the last
    # recognized keyword, defaulting to the header if no keyword was recognized.
    pending_comments = String[]
    last_section     = 1

    # == Version ===========================================================================

    version_line = _kvn__next_line!(scanner)
    km           = isnothing(version_line) ? nothing : _kvn__parse_keyword(version_line)

    (isnothing(km) || (km[1] != "CCSDS_OMM_VERS")) &&
        throw(OdmParseError("The KVN OMM must start with the `CCSDS_OMM_VERS` keyword."))

    version = tryparse(Float64, km[2])

    isnothing(version) && throw(
        OdmParseError(
            "Invalid value for the KVN keyword `CCSDS_OMM_VERS` in line $(scanner.line): " *
            "$(km[2]).";
            keyword = "CCSDS_OMM_VERS",
            line = scanner.line,
        ),
    )

    builder.version = version

    # == Fields ============================================================================

    while true
        line = _kvn__next_line!(scanner)
        isnothing(line) && break

        l  = scanner.line
        km = _kvn__parse_keyword(line)

        isnothing(km) &&
            throw(OdmParseError("Invalid KVN keyword format in line $l: $line."; line = l))

        key, value = km

        if key == "COMMENT"
            push!(pending_comments, String(value))
            continue
        end

        # A version keyword starts a new message, so we stop processing here.
        if !isnothing(_kvn_odm__message_index(key))
            _kvn__unread_line!(scanner)
            break
        end

        # User-defined parameters use the keyword prefix `USER_DEFINED_`. The prefix is
        # stripped so that the parameter names match the XML representation, in which they
        # are stored in the `parameter` attribute.
        if startswith(key, "USER_DEFINED_")
            # The user-defined parameters section has no comments field, so the pending
            # comments are assigned to the data section.
            _kvn_omm__flush_comments!(builder.data.comments, pending_comments)

            push!(
                builder.data.user_defined_parameters,
                String(chopprefix(key, "USER_DEFINED_")) => String(value),
            )
            continue
        end

        section_and_field = get(_KVN_OMM__KEYWORD_TO_SECTION_AND_FIELD, key, nothing)

        if isnothing(section_and_field)
            @warn "Unrecognized KVN keyword in line $l: $key."
            continue
        end

        section, field = section_and_field

        _kvn_omm__field_is_set(builder, section, field) && throw(
            OdmParseError(
                "Duplicate OMM keyword `$key` in line $l."; keyword = key, line = l
            ),
        )

        _kvn_omm__flush_comments!(_kvn_omm__comments(builder, section), pending_comments)
        last_section = section

        # An empty value is treated as an absent field.
        isempty(value) && continue

        _kvn_omm__set_field!(builder, section, field, value, key)
    end

    # Assign the trailing comments to the section of the last recognized keyword.
    _kvn_omm__flush_comments!(_kvn_omm__comments(builder, last_section), pending_comments)

    return builder
end

"""
    _kvn_omm__flush_comments!(
        comments::Vector{String},
        pending_comments::Vector{String}
    ) -> Nothing

Move the `pending_comments` to the section `comments`, leaving `pending_comments` empty.
"""
function _kvn_omm__flush_comments!(
    comments::Vector{String}, pending_comments::Vector{String}
)
    isempty(pending_comments) && return nothing
    append!(comments, pending_comments)
    empty!(pending_comments)
    return nothing
end

"""
    _kvn_omm__comments(builder::_OmmBuilder, section::Int) -> Vector{String}

Return the comments vector of the KVN `section` (see
`_KVN_OMM__KEYWORD_TO_SECTION_AND_FIELD`) in `builder`. The covariance matrix builder is
created if it does not exist yet.
"""
function _kvn_omm__comments(builder::_OmmBuilder, section::Int)
    section == 1 && return builder.header.comments
    section == 2 && return builder.metadata.comments
    section == 3 && return builder.data.mean_elements_comments
    section == 4 && return builder.data.spacecraft_parameters_comments
    section == 5 && return builder.data.tle_parameters_comments
    return _kvn_omm__covariance_matrix!(builder).comments
end

"""
    _kvn_omm__covariance_matrix!(builder::_OmmBuilder) -> _OmmCovarianceMatrixBuilder

Return the covariance matrix builder in `builder`, creating it if it does not exist yet.
"""
function _kvn_omm__covariance_matrix!(builder::_OmmBuilder)
    covariance_matrix = builder.data.covariance_matrix
    isnothing(covariance_matrix) || return covariance_matrix
    return builder.data.covariance_matrix = _OmmCovarianceMatrixBuilder()
end

"""
    _kvn_omm__field_is_set(builder::_OmmBuilder, section::Int, field::Symbol) -> Bool

Check if the `field` of the KVN `section` (see `_KVN_OMM__KEYWORD_TO_SECTION_AND_FIELD`)
was already set in `builder`. The branch on the section keeps the call statically typed.
"""
function _kvn_omm__field_is_set(builder::_OmmBuilder, section::Int, field::Symbol)
    section == 1 && return _omm_field_is_set(builder.header, field)
    section == 2 && return _omm_field_is_set(builder.metadata, field)
    section <= 5 && return _omm_field_is_set(builder.data, field)
    covariance_matrix = builder.data.covariance_matrix
    isnothing(covariance_matrix) && return false
    return _omm_field_is_set(covariance_matrix, field)
end

"""
    _kvn_omm__set_field!(
        builder::_OmmBuilder,
        section::Int,
        field::Symbol,
        value::AbstractString,
        keyword::AbstractString
    ) -> Nothing

Parse the raw `value` of the CCSDS `keyword` and store it in the `field` of the KVN
`section` (see `_KVN_OMM__KEYWORD_TO_SECTION_AND_FIELD`) in `builder`. The branch on the
section keeps the call statically typed.
"""
function _kvn_omm__set_field!(
    builder::_OmmBuilder,
    section::Int,
    field::Symbol,
    value::AbstractString,
    keyword::AbstractString,
)
    section == 1 && return _omm_set_field!(builder.header, field, value, keyword)
    section == 2 && return _omm_set_field!(builder.metadata, field, value, keyword)
    section <= 5 && return _omm_set_field!(builder.data, field, value, keyword)
    return _omm_set_field!(_kvn_omm__covariance_matrix!(builder), field, value, keyword)
end
