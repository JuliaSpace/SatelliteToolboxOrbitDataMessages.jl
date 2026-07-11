## Description #############################################################################
#
# Functions to write Orbit Mean-Elements Message (OMM) files.
#
############################################################################################

export write_omm

"""
    write_omm(io::IO, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the provided `io` stream in XML format.

    write_omm(file::AbstractString, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the file at `file` in XML format, overwriting its contents.
"""
function write_omm(io::IO, omm::OrbitMeanElementsMessage)
    doc = _omm_to_xml(omm, Val(true))

    XML.write(io, doc)
    return nothing
end

function write_omm(file::AbstractString, omm::OrbitMeanElementsMessage)
    open(file, "w") do io
        write_omm(io, omm)
    end

    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _omm_to_xml(omm::OrbitMeanElementsMessage, stand_alone::Val{true}) -> XML.Document

Convert the given `omm` to an XML Document assuming it is a stand-alone document. Hence, the
XML declaration is included.

    _omm_to_xml(omm::OrbitMeanElementsMessage, stand_alone::Val{false}) -> XML.Element

Convert the given `omm` to an XML Element assuming it is to be embedded within another XML
document. Hence, the XML declaration is omitted.

The written version is always `3.0`, regardless of the version stored in the `omm`. This
matches the schema against which the output is validated.
"""
function _omm_to_xml(omm::OrbitMeanElementsMessage, stand_alone::Val{true})
    _validate_writable_omm_header(omm)
    doc = XML.Document()

    # XML Declaration.
    decl = XML.Declaration(; version = "1.0", encoding = "UTF-8")
    push!(doc, decl)

    # Our XML is compatible with version 3.
    root = XML.Element(
        "omm";
        id = "CCSDS_OMM_VERS",
        version = "3.0",
        var"xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance",
        var"xsi:noNamespaceSchemaLocation" =
            "https://sanaregistry.org/files/ndmxml_unqualified/ndmxml-4.0.0-master-4.0.xsd"
    )

    push!(doc, root)

    _add_omm_tags!(root, omm)

    return doc
end

function _omm_to_xml(omm::OrbitMeanElementsMessage, stand_alone::Val{false})
    _validate_writable_omm_header(omm)
    doc = XML.Element(
        "omm";
        id = "CCSDS_OMM_VERS",
        version = "3.0"
    )

    _add_omm_tags!(doc, omm)

    return doc
end

"""
    _add_omm_tags!(parent::XML.Node, omm::OrbitMeanElementsMessage) -> Nothing

Add the OMM tags from the given `omm` message to the `parent` XML node.
"""
function _add_omm_tags!(parent::XML.Node, omm::OrbitMeanElementsMessage)
    # == Header ============================================================================

    header = omm.header
    header_node = XML.Element("header")
    push!(parent, header_node)

    foreach(comment -> _xml_add_tag!(header_node, "COMMENT", comment), header.comments)
    _xml_add_tag!(header_node, "CLASSIFICATION", header.classification)
    _xml_add_tag!(header_node, "CREATION_DATE",  omm.header.creation_date)
    _xml_add_tag!(header_node, "ORIGINATOR",     header.originator)
    _xml_add_tag!(header_node, "MESSAGE_ID",     header.message_id)

    # == Body ==============================================================================

    body_node = XML.Element("body")
    push!(parent, body_node)

    segment_node = XML.Element("segment")
    push!(body_node, segment_node)

    # -- Metadata --------------------------------------------------------------------------

    metadata = omm.body.segment.metadata
    metadata_node = XML.Element("metadata")
    push!(segment_node, metadata_node)

    foreach(comment -> _xml_add_tag!(metadata_node, "COMMENT", comment), metadata.comments)
    _xml_add_tag!(metadata_node, "OBJECT_NAME",         metadata.object_name)
    _xml_add_tag!(metadata_node, "OBJECT_ID",           metadata.object_id)
    _xml_add_tag!(metadata_node, "CENTER_NAME",         metadata.center_name)
    _xml_add_tag!(metadata_node, "REF_FRAME",           metadata.ref_frame)
    _xml_add_tag!(metadata_node, "REF_FRAME_EPOCH",     metadata.ref_frame_epoch)
    _xml_add_tag!(metadata_node, "TIME_SYSTEM",         metadata.time_system)
    _xml_add_tag!(metadata_node, "MEAN_ELEMENT_THEORY", metadata.mean_element_theory)

    # -- Data ------------------------------------------------------------------------------

    data = omm.body.segment.data
    data_node = XML.Element("data")
    push!(segment_node, data_node)

    foreach(comment -> _xml_add_tag!(data_node, "COMMENT", comment), data.comments)

    # .. Mean Keplerian Elements ...........................................................

    mean_kep_node = XML.Element("meanElements")
    push!(data_node, mean_kep_node)

    foreach(
        comment -> _xml_add_tag!(mean_kep_node, "COMMENT", comment),
        data.mean_elements_comments,
    )
    _xml_add_tag!(mean_kep_node, "EPOCH",             data.epoch)
    _xml_add_tag!(mean_kep_node, "SEMI_MAJOR_AXIS",   data.semi_major_axis)
    _xml_add_tag!(mean_kep_node, "MEAN_MOTION",       data.mean_motion)
    _xml_add_tag!(mean_kep_node, "ECCENTRICITY",      data.eccentricity)
    _xml_add_tag!(mean_kep_node, "INCLINATION",       data.inclination)
    _xml_add_tag!(mean_kep_node, "RA_OF_ASC_NODE",    data.raan)
    _xml_add_tag!(mean_kep_node, "ARG_OF_PERICENTER", data.arg_of_pericenter)
    _xml_add_tag!(mean_kep_node, "MEAN_ANOMALY",      data.mean_anomaly)
    _xml_add_tag!(mean_kep_node, "GM",                data.GM)

    # .. Spacecraft Parameters .............................................................

    sc_params_node = XML.Element("spacecraftParameters")

    foreach(
        comment -> _xml_add_tag!(sc_params_node, "COMMENT", comment),
        data.spacecraft_parameters_comments,
    )
    _xml_add_tag!(sc_params_node, "MASS",            data.mass)
    _xml_add_tag!(sc_params_node, "SOLAR_RAD_AREA",  data.solar_rad_area)
    _xml_add_tag!(sc_params_node, "SOLAR_RAD_COEFF", data.solar_rad_coeff)
    _xml_add_tag!(sc_params_node, "DRAG_AREA",       data.drag_area)
    _xml_add_tag!(sc_params_node, "DRAG_COEFF",      data.drag_coeff)

    isempty(children(sc_params_node)) || push!(data_node, sc_params_node)

    # .. TLE Related Parameters ............................................................

    tle_params_node = XML.Element("tleParameters")

    foreach(
        comment -> _xml_add_tag!(tle_params_node, "COMMENT", comment),
        data.tle_parameters_comments,
    )
    _xml_add_tag!(tle_params_node, "EPHEMERIS_TYPE",      data.ephemeris_type)
    _xml_add_tag!(tle_params_node, "CLASSIFICATION_TYPE", data.classification_type)
    _xml_add_tag!(tle_params_node, "NORAD_CAT_ID",        data.norad_cat_id)
    _xml_add_tag!(tle_params_node, "ELEMENT_SET_NO",      data.element_set_number)
    _xml_add_tag!(tle_params_node, "REV_AT_EPOCH",        data.rev_at_epoch)
    _xml_add_tag!(tle_params_node, "BSTAR",               data.bstar)
    _xml_add_tag!(tle_params_node, "BTERM",               data.bterm)
    _xml_add_tag!(tle_params_node, "MEAN_MOTION_DOT",     data.mean_motion_dot)
    _xml_add_tag!(tle_params_node, "MEAN_MOTION_DDOT",    data.mean_motion_ddot)
    _xml_add_tag!(tle_params_node, "AGOM",                data.agom)

    isempty(children(tle_params_node)) || push!(data_node, tle_params_node)

    # .. Covariance Matrix ................................................................

    if !isnothing(data.covariance_matrix)
        cov = data.covariance_matrix
        cov_node = XML.Element("covarianceMatrix")

        foreach(comment -> _xml_add_tag!(cov_node, "COMMENT", comment), cov.comments)
        _xml_add_tag!(cov_node, "COV_REF_FRAME",  cov.cov_ref_frame)
        _xml_add_tag!(cov_node, "CX_X",           cov.cx_x)
        _xml_add_tag!(cov_node, "CY_X",           cov.cy_x)
        _xml_add_tag!(cov_node, "CY_Y",           cov.cy_y)
        _xml_add_tag!(cov_node, "CZ_X",           cov.cz_x)
        _xml_add_tag!(cov_node, "CZ_Y",           cov.cz_y)
        _xml_add_tag!(cov_node, "CZ_Z",           cov.cz_z)
        _xml_add_tag!(cov_node, "CX_DOT_X",       cov.cx_dot_x)
        _xml_add_tag!(cov_node, "CX_DOT_Y",       cov.cx_dot_y)
        _xml_add_tag!(cov_node, "CX_DOT_Z",       cov.cx_dot_z)
        _xml_add_tag!(cov_node, "CX_DOT_X_DOT",   cov.cx_dot_x_dot)
        _xml_add_tag!(cov_node, "CY_DOT_X",       cov.cy_dot_x)
        _xml_add_tag!(cov_node, "CY_DOT_Y",       cov.cy_dot_y)
        _xml_add_tag!(cov_node, "CY_DOT_Z",       cov.cy_dot_z)
        _xml_add_tag!(cov_node, "CY_DOT_X_DOT",   cov.cy_dot_x_dot)
        _xml_add_tag!(cov_node, "CY_DOT_Y_DOT",   cov.cy_dot_y_dot)
        _xml_add_tag!(cov_node, "CZ_DOT_X",       cov.cz_dot_x)
        _xml_add_tag!(cov_node, "CZ_DOT_Y",       cov.cz_dot_y)
        _xml_add_tag!(cov_node, "CZ_DOT_Z",       cov.cz_dot_z)
        _xml_add_tag!(cov_node, "CZ_DOT_X_DOT",   cov.cz_dot_x_dot)
        _xml_add_tag!(cov_node, "CZ_DOT_Y_DOT",   cov.cz_dot_y_dot)
        _xml_add_tag!(cov_node, "CZ_DOT_Z_DOT",   cov.cz_dot_z_dot)

        push!(data_node, cov_node)
    end

    # .. User-Defined Parameters ...........................................................

    if !isnothing(data.user_defined_parameters)
        user_defined_parameter_nodes = XML.Element("userDefinedParameters")

        for (key, value) in data.user_defined_parameters
            child = XML.Element("USER_DEFINED"; parameter = key)
            push!(child, XML.Text(_xml_render(value)))
            push!(user_defined_parameter_nodes, child)
        end

        push!(data_node, user_defined_parameter_nodes)
    end

    return nothing
end

"""
    _validate_writable_omm_header(omm::OrbitMeanElementsMessage) -> Nothing

Validate that the header of `omm` contains the fields required for OMM 3.0 output.
"""
function _validate_writable_omm_header(omm::OrbitMeanElementsMessage)
    isnothing(omm.header.creation_date) && throw(ArgumentError(
        "Cannot write OMM 3.0 without a creation date."
    ))
    isempty(omm.header.originator) && throw(ArgumentError(
        "Cannot write OMM 3.0 without an originator."
    ))
    return nothing
end
