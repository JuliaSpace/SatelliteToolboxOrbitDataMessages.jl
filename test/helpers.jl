## Description #############################################################################
#
# Shared helpers and fixtures for the test suite.
#
############################################################################################

const _FIXTURE_FILE = joinpath(@__DIR__, "2025-12-30-Amazonia_1.xml")

"""
    _fixture_omm_xml() -> String

Return the raw XML string of the Amazonia 1 fixture file.
"""
function _fixture_omm_xml()
    return read(_FIXTURE_FILE, String)
end

"""
    _minimal_omm_xml(; kwargs...) -> String

Build a minimal valid OMM XML string. Optional tags can be provided via keyword arguments:
- `omm_version::String = "3.0"`
- `header_comment::String = ""`
- `classification::String = ""`
- `creation_date::String = "2025-12-30T23:36:37"`
- `originator::String = "18 SPCS"`
- `message_id::String = ""`
- `metadata_comment::String = ""`
- `object_name::String = "AMAZONIA 1"`
- `object_id::String = "2021-015A"`
- `center_name::String = "EARTH"`
- `ref_frame::String = "TEME"`
- `ref_frame_epoch::String = ""`
- `time_system::String = "UTC"`
- `mean_element_theory::String = "SGP4"`
- `data_comment::String = ""`
- `epoch::String = "2025-12-30T18:12:04.533984"`
- `semi_major_axis::String = ""`
- `mean_motion::String = "14.40772474"`
- `eccentricity::String = "0.00011240"`
- `inclination::String = "98.3721"`
- `raan::String = "75.0877"`
- `arg_of_pericenter::String = "97.3772"`
- `mean_anomaly::String = "262.7545"`
- `gm::String = ""`
- `spacecraft_params_xml::String = ""` (raw XML for spacecraftParameters)
- `tle_params_xml::String = ""` (raw XML for tleParameters)
- `covariance_matrix_xml::String = ""` (raw XML for covarianceMatrix)
- `user_defined_xml::String = ""` (raw XML for userDefinedParameters)
- `extra_inner::String = ""` (raw XML inserted inside <omm>, e.g. extra segments)

The `extra_inner` keyword allows inserting raw XML inside the <omm> element (e.g. for
testing multiple segments).
"""
function _minimal_omm_xml(;
    omm_version::String = "3.0",
    omm_id::String = "CCSDS_OMM_VERS",
    header_comment::String = "",
    classification::String = "",
    creation_date::String = "2025-12-30T23:36:37",
    originator::String = "18 SPCS",
    message_id::String = "",
    metadata_comment::String = "",
    object_name::String = "AMAZONIA 1",
    object_id::String = "2021-015A",
    center_name::String = "EARTH",
    ref_frame::String = "TEME",
    ref_frame_epoch::String = "",
    time_system::String = "UTC",
    mean_element_theory::String = "SGP4",
    data_comment::String = "",
    epoch::String = "2025-12-30T18:12:04.533984",
    semi_major_axis::String = "",
    mean_motion::String = "14.40772474",
    eccentricity::String = "0.00011240",
    inclination::String = "98.3721",
    raan::String = "75.0877",
    arg_of_pericenter::String = "97.3772",
    mean_anomaly::String = "262.7545",
    gm::String = "",
    spacecraft_params_xml::String = "",
    tle_params_xml::String = "",
    covariance_matrix_xml::String = "",
    user_defined_xml::String = "",
    extra_inner::String = "",
)
    function _tag(name::String, value::String)
        isempty(value) && return ""
        return "<$name>$value</$name>"
    end

    header_inner = join(filter(!isempty, [
        _tag("COMMENT", header_comment),
        _tag("CLASSIFICATION", classification),
        _tag("CREATION_DATE", creation_date),
        _tag("ORIGINATOR", originator),
        _tag("MESSAGE_ID", message_id),
    ]))

    metadata_inner = join(filter(!isempty, [
        _tag("COMMENT", metadata_comment),
        _tag("OBJECT_NAME", object_name),
        _tag("OBJECT_ID", object_id),
        _tag("CENTER_NAME", center_name),
        _tag("REF_FRAME", ref_frame),
        _tag("REF_FRAME_EPOCH", ref_frame_epoch),
        _tag("TIME_SYSTEM", time_system),
        _tag("MEAN_ELEMENT_THEORY", mean_element_theory),
    ]))

    mean_elements_inner = join(filter(!isempty, [
        _tag("COMMENT", data_comment),
        _tag("EPOCH", epoch),
        _tag("SEMI_MAJOR_AXIS", semi_major_axis),
        _tag("MEAN_MOTION", mean_motion),
        _tag("ECCENTRICITY", eccentricity),
        _tag("INCLINATION", inclination),
        _tag("RA_OF_ASC_NODE", raan),
        _tag("ARG_OF_PERICENTER", arg_of_pericenter),
        _tag("MEAN_ANOMALY", mean_anomaly),
        _tag("GM", gm),
    ]))

    data_inner = join(filter(!isempty, [
        "<meanElements>$(mean_elements_inner)</meanElements>",
        spacecraft_params_xml,
        tle_params_xml,
        covariance_matrix_xml,
        user_defined_xml,
    ]))

    segment_inner = "<metadata>$(metadata_inner)</metadata><data>$(data_inner)</data>"

    body_inner = "<segment>$(segment_inner)</segment>"

    omm_inner = join(filter(!isempty, [
        "<header>$(header_inner)</header>",
        "<body>$(body_inner)</body>",
        extra_inner,
    ]))

    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <omm id="$(omm_id)" version="$(omm_version)">$(omm_inner)</omm>
    """

    return xml
end

"""
    _ndm_xml(odm_xmls::String...) -> String

Wrap one or more ODM XML strings in an <ndm> container. Each argument should be a complete
ODM element (without the XML declaration).
"""
function _ndm_xml(odm_xmls::AbstractString...)
    inner      = join(odm_xmls)
    schema_url = "https://sanaregistry.org/r/ndmxml_unqualified/" *
        "ndmxml-3.0.0-master-3.0.xsd"
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <ndm xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="$(schema_url)">$(inner)</ndm>
    """
end

"""
    _omm_element_from_fixture() -> String

Extract the <omm>...</omm> element (without XML declaration) from the fixture file.
"""
function _omm_element_from_fixture()
    str = _fixture_omm_xml()
    m = match(r"<omm.*</omm>", str)
    return m.match
end
