## Description #############################################################################
#
# Functions to write Orbit Mean-Elements Message (OMM) files.
#
############################################################################################

export write_omm

"""
    write_omm(io::IO, omm::OrbitMeanElementsMessage) -> Nothing

Write the given `omm` to the provided `io` stream in XML format.
"""
function write_omm(io::IO, omm::OrbitMeanElementsMessage)
    doc = _omm_to_xml(omm)

    doc["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    doc["xsi:noNamespaceSchemaLocation"] =
        "https://sanaregistry.org/r/ndmxml_unqualified/ndmxml-3.0.0-master-3.0.xsd"

    XML.write(io, doc)
    return nothing
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _omm_to_xml(omm::OrbitMeanElementsMessage) -> XML.Element

Convert the given `omm` to an XML node represented by a `XML.Element`.
"""
function _omm_to_xml(omm::OrbitMeanElementsMessage)
    doc = XML.Element("omm")
    doc["id"] = "CCSDS_OMM_VERS"
    doc["version"] = "$(omm.version.major).$(omm.version.minor)"

    # == Header ============================================================================

    header = omm.header
    header_node = XML.Element("header")
    push!(doc, header_node)

    _xml_add_tag!(header_node, "COMMENT",        header.comment)
    _xml_add_tag!(header_node, "CLASSIFICATION", header.classification)
    _xml_add_tag!(header_node, "CREATION_DATE",  omm.header.creation_date)
    _xml_add_tag!(header_node, "ORIGINATOR",     header.originator)
    _xml_add_tag!(header_node, "MESSAGE_ID",     header.message_id)

    # == Body ==============================================================================

    body_node = XML.Element("body")
    push!(doc, body_node)

    segment_node = XML.Element("segment")
    push!(body_node, segment_node)

    # -- Metadata --------------------------------------------------------------------------

    metadata = omm.body.segment.metadata
    metadata_node = XML.Element("metadata")
    push!(segment_node, metadata_node)

    _xml_add_tag!(metadata_node, "COMMENT",             metadata.comment)
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

    # .. Mean Keplerian Elements ...........................................................

    mean_kep_node = XML.Element("meanElements")
    push!(data_node, mean_kep_node)

    _xml_add_tag!(mean_kep_node, "COMMENT",           data.data_comment)
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

    _xml_add_tag!(sc_params_node, "COMMENT",         data.spacecraft_data_comment)
    _xml_add_tag!(sc_params_node, "MASS",            data.mass)
    _xml_add_tag!(sc_params_node, "SOLAR_RAD_AREA",  data.solar_rad_area)
    _xml_add_tag!(sc_params_node, "SOLAR_RAD_COEFF", data.solar_rad_coeff)
    _xml_add_tag!(sc_params_node, "DRAG_AREA",       data.drag_area)
    _xml_add_tag!(sc_params_node, "DRAG_COEFF",      data.drag_coeff)

    isempty(sc_params_node.children) || push!(data_node, sc_params_node)

    # .. TLE Related Parameters ............................................................

    tle_params_node = XML.Element("tleParameters")

    _xml_add_tag!(tle_params_node, "COMMENT",             data.tle_parameters_comment)
    _xml_add_tag!(tle_params_node, "EPHEMERIS_TYPE",      data.ephemeris_type)
    _xml_add_tag!(tle_params_node, "CLASSIFICATION_TYPE", data.classification_type)
    _xml_add_tag!(tle_params_node, "NORAD_CAT_ID",        data.norad_cat_id)
    _xml_add_tag!(tle_params_node, "ELEMENT_SET_NO",      data.element_set_number)
    _xml_add_tag!(tle_params_node, "REV_AT_EPOCH",        data.rev_at_epoch)
    _xml_add_tag!(tle_params_node, "BSTAR",               data.bstar)
    _xml_add_tag!(tle_params_node, "MEAN_MOTION_DOT",     data.mean_motion_dot)
    _xml_add_tag!(tle_params_node, "MEAN_MOTION_DDOT",    data.mean_motion_ddot)

    isempty(tle_params_node.children) || push!(data_node, tle_params_node)

    # .. User-Defined Parameters ...........................................................

    if !isnothing(data.user_defined_parameters)
        user_defined_parameter_nodes = XML.Element("userDefinedParameters")

        for (key, value) in data.user_defined_parameters
            child = XML.Element("USER_DEFINED")
            child["parameter"] = key
            push!(child, XML.Text(_xml_render(value)))
            push!(user_defined_parameter_nodes, child)
        end

        push!(data_node, user_defined_parameter_nodes)
    end

    return doc
end
