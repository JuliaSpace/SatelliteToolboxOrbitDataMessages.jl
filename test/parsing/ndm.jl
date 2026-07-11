## Description #############################################################################
#
# NDM container tests.
#
############################################################################################

@testset "NDM Container" verbose = true begin
    omm_elem = _omm_element_from_fixture()
    ndm_xml  = _ndm_xml(omm_elem, omm_elem)

    # == NDM With Two <omm> -> parse_omms Returns 2-Vector =================================

    @testset "parse_omms on NDM With Two OMMs" begin
        omms = parse_omms(ndm_xml)
        @test !isnothing(omms)
        @test length(omms) == 2
        @test all(o -> o isa OrbitMeanElementsMessage, omms)
    end

    # == parse_omm on NDM Returns First OMM ================================================

    @testset "parse_omm on NDM Returns First" begin
        omm = parse_omm(ndm_xml)
        @test !isnothing(omm)
        @test omm isa OrbitMeanElementsMessage
        @test omm.body.segment.metadata.object_name == "AMAZONIA 1"
    end

    # == parse_odm on NDM Returns 2-Vector =================================================

    @testset "parse_odm on NDM With Two OMMs" begin
        vodm = parse_odm(ndm_xml)
        @test !isnothing(vodm)
        @test vodm isa Vector{OrbitDataMessage}
        @test length(vodm) == 2
    end

    # == parse_omms on Single-OMM Document Returns 1-Vector ================================

    @testset "parse_omms on Single-OMM Doc" begin
        single_xml = _minimal_omm_xml()
        omms = parse_omms(single_xml)
        @test !isnothing(omms)
        @test length(omms) == 1
    end

    # == Unsupported ODMs ==================================================================

    opm_elem = """
    <opm id="CCSDS_OPM_VERS" version="3.0"><header/><body/></opm>
    """
    oem_elem = """
    <oem id="CCSDS_OEM_VERS" version="3.0"><header/><body/></oem>
    """
    ocm_elem = """
    <ocm id="CCSDS_OCM_VERS" version="3.0"><header/><body/></ocm>
    """

    opm_warning = "We do not support Orbit Parameter Messages (OPM) yet."
    oem_warning = "We do not support Orbit Ephemeris Messages (OEM) yet."
    ocm_warning = "We do not support Orbit Comprehensive Messages (OCM) yet."

    @testset "Unsupported Stand-Alone ODMs" begin
        @test_logs (:warn, opm_warning) @test isempty(parse_odm(opm_elem))
        @test_logs (:warn, oem_warning) @test isempty(parse_odm(oem_elem))
        @test_logs (:warn, ocm_warning) @test isempty(parse_odm(ocm_elem))

        @test_logs (:warn, opm_warning) @test isempty(parse_omms(opm_elem))
        @test_logs (:warn, oem_warning) @test isempty(parse_omms(oem_elem))
        @test_logs (:warn, ocm_warning) @test isempty(parse_omms(ocm_elem))
    end

    # == Mixed NDM =========================================================================

    @testset "Mixed NDM Skips Unsupported ODMs" begin
        mixed_ndm = _ndm_xml(opm_elem, omm_elem, oem_elem, ocm_elem)

        @test_logs (:warn, opm_warning) (:warn, oem_warning) (:warn, ocm_warning) begin
            odms = parse_odm(mixed_ndm)
            @test length(odms) == 1
            @test only(odms) isa OrbitMeanElementsMessage
        end

        @test_logs (:warn, opm_warning) (:warn, oem_warning) (:warn, ocm_warning) begin
            omms = parse_omms(mixed_ndm)
            @test length(omms) == 1
            @test only(omms).body.segment.metadata.object_name == "AMAZONIA 1"
        end
    end
end
