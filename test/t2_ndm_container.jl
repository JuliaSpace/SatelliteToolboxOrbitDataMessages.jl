## Description #############################################################################
#
# T2 — NDM container tests.
#
############################################################################################

@testset "T2: NDM container" verbose = true begin
    omm_elem = _omm_element_from_fixture()
    ndm_xml  = _ndm_xml(omm_elem, omm_elem)

    # == T2.1: NDM with two <omm> -> parse_omms returns 2-vector ========================

    @testset "T2.1: parse_omms on NDM with two OMMs" begin
        omms = parse_omms(ndm_xml)
        @test !isnothing(omms)
        @test length(omms) == 2
        @test all(o -> o isa OrbitMeanElementsMessage, omms)
    end

    # == T2.2: parse_omm on NDM returns first OMM =======================================

    @testset "T2.2: parse_omm on NDM returns first" begin
        omm = parse_omm(ndm_xml)
        @test !isnothing(omm)
        @test omm isa OrbitMeanElementsMessage
        @test omm.body.segment.metadata.object_name == "AMAZONIA 1"
    end

    # == T2.3: parse_odm on NDM returns 2-vector ========================================

    @testset "T2.3: parse_odm on NDM with two OMMs" begin
        vodm = parse_odm(ndm_xml)
        @test !isnothing(vodm)
        @test vodm isa Vector{OrbitDataMessage}
        @test length(vodm) == 2
    end

    # == T2.4: parse_omms on single-OMM document returns 1-vector =======================

    @testset "T2.4: parse_omms on single-OMM doc" begin
        single_xml = _minimal_omm_xml()
        omms = parse_omms(single_xml)
        @test !isnothing(omms)
        @test length(omms) == 1
    end
end
