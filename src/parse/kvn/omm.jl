## Description #############################################################################
#
# Parse Orbit Mean-Elements Messages (OMM) using KVN input.
#
############################################################################################

"""
    _kvn_omm__parse(str::AbstractString) -> OrbitMeanElementsMessage

Parse the Orbit Mean-Elements Message (OMM) in the KVN input `str` and return the parsed
message.
"""
function _kvn_omm__parse(str::AbstractString)
    version                 = nothing
    header_fields           = Dict{Symbol, Any}()
    metadata_fields         = Dict{Symbol, Any}()
    data_fields             = Dict{Symbol, Any}()
    covariance_fields       = Dict{Symbol, Any}()
    user_defined_parameters = Pair{String, String}[]

    # Tuples with the keyword mapping of each OMM section, the dictionary in which its
    # fields are stored, and the dictionary key that holds its comments. The KVN format is
    # flat, so the keyword sets of all sections are searched in sequence. The covariance
    # matrix fields are kept in a separate dictionary because they belong to
    # `OmmCovarianceMatrix`, which is assembled from the nested
    # `data_fields[:covariance_matrix]`.
    section_mappings = (
        (_OMM_HEADER_KEYWORD_TO_FIELD, header_fields, :comments),
        (_OMM_METADATA_KEYWORD_TO_FIELD, metadata_fields, :comments),
        (_OMM_MEAN_ELEMENTS_KEYWORD_TO_FIELD, data_fields, :mean_elements_comments),
        (
            _OMM_SPACECRAFT_PARAMETERS_KEYWORD_TO_FIELD,
            data_fields,
            :spacecraft_parameters_comments
        ),
        (_OMM_TLE_PARAMETERS_KEYWORD_TO_FIELD, data_fields, :tle_parameters_comments),
        (_OMM_COVARIANCE_KEYWORD_TO_FIELD, covariance_fields, :comments),
    )

    # Comments precede the content of the section they refer to in KVN files. Hence, we
    # buffer consecutive comment lines and assign them to the section of the next
    # recognized keyword. Comments at the end of the message are assigned to the section
    # of the last recognized keyword.
    pending_comments = String[]
    last_comments    = nothing

    # Flush the pending comments to the `fields` dictionary under the `comments_key`.
    flush_comments!(fields::Dict{Symbol, Any}, comments_key::Symbol) = begin
        isempty(pending_comments) && return (fields, comments_key)
        comments = get!(() -> String[], fields, comments_key)
        append!(comments, pending_comments)
        empty!(pending_comments)
        return (fields, comments_key)
    end

    # == Parse File ========================================================================

    for (l, line) in enumerate(eachsplit(str, '\n'))
        sline = strip(line)
        isempty(sline) && continue

        km = _kvn__parse_keyword(sline)

        isnothing(km) && throw(ArgumentError(
            "Invalid KVN keyword format in line $l: $line."
        ))

        key, value = km

        if key == "COMMENT"
            push!(pending_comments, String(value))
            continue
        end

        if key == "CCSDS_OMM_VERS"
            # If the version was already assigned, we are starting a new OMM, so we stop
            # processing here.
            isnothing(version) || break

            version = tryparse(Float64, value)

            isnothing(version) && throw(ArgumentError(
                "Invalid value for the KVN keyword `CCSDS_OMM_VERS` in line $l: $value."
            ))

            continue
        end

        # User-defined parameters use the keyword prefix `USER_DEFINED_`. The prefix is
        # stripped so that the parameter names match the XML representation, in which they
        # are stored in the `parameter` attribute.
        if startswith(key, "USER_DEFINED_")
            # The user-defined parameters section has no comments field, so the pending
            # comments are assigned to the data section.
            last_comments = flush_comments!(data_fields, :comments)

            push!(
                user_defined_parameters,
                String(chopprefix(key, "USER_DEFINED_")) => String(value)
            )
            continue
        end

        recognized = false

        for (mapping, fields, comments_key) in section_mappings
            field = get(mapping, key, nothing)
            isnothing(field) && continue

            last_comments = flush_comments!(fields, comments_key)

            fields[field] = _omm_parse_field(_omm_field_type(field), value, key)
            recognized = true
            break
        end

        recognized || @warn "Unrecognized KVN keyword in line $l: $key."
    end

    # Assign the trailing comments to the section of the last recognized keyword,
    # defaulting to the header if no keyword was recognized.
    if !isempty(pending_comments)
        fields, comments_key = something(last_comments, (header_fields, :comments))
        flush_comments!(fields, comments_key)
    end

    isempty(covariance_fields) || (data_fields[:covariance_matrix] = covariance_fields)

    isempty(user_defined_parameters) ||
        (data_fields[:user_defined_parameters] = user_defined_parameters)

    # == Create OMM Object =================================================================

    return (;
        version         = version,
        header_fields   = header_fields,
        metadata_fields = metadata_fields,
        data_fields     = data_fields,
    )
end
