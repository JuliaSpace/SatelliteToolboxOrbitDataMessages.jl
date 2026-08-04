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

    # Pairs with the keyword mapping of each OMM section and the dictionary in which its
    # fields are stored. The KVN format is flat, so the keyword sets of all sections are
    # searched in sequence. The covariance matrix fields are kept in a separate dictionary
    # because they belong to `OmmCovarianceMatrix`, which is assembled from the nested
    # `data_fields[:covariance_matrix]`.
    section_mappings = (
        (_OMM_HEADER_KEYWORD_TO_FIELD,     header_fields),
        (_OMM_METADATA_KEYWORD_TO_FIELD,   metadata_fields),
        (_OMM_DATA_KEYWORD_TO_FIELD,       data_fields),
        (_OMM_COVARIANCE_KEYWORD_TO_FIELD, covariance_fields),
    )

    # == Parse File ========================================================================

    for (l, line) in enumerate(eachsplit(str, '\n'))
        sline = strip(line)
        isempty(sline) && continue

        km = _kvn__parse_keyword(sline)

        isnothing(km) && throw(ArgumentError(
            "Invalid KVN keyword format in line $l: $line."
        ))

        key, value = km

        key == "COMMENT" && continue

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
            push!(
                user_defined_parameters,
                String(chopprefix(key, "USER_DEFINED_")) => String(value)
            )
            continue
        end

        recognized = false

        for (mapping, fields) in section_mappings
            field = get(mapping, key, nothing)
            isnothing(field) && continue

            fields[field] = _omm_parse_field(_omm_field_type(field), value, key)
            recognized = true
            break
        end

        recognized || @warn "Unrecognized KVN keyword in line $l: $key."
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
