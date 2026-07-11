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
end
