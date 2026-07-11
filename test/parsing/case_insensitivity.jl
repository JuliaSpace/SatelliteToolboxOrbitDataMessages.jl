## Description #############################################################################
#
# XML tag case-sensitivity tests.
#
############################################################################################

@testset "Tag Case-Sensitivity" verbose = true begin
    xml = _minimal_omm_xml()

    @testset "Structural Tag" begin
        mixed_case = replace(xml, "<header>" => "<Header>", "</header>" => "</Header>")
        @test_throws ArgumentError parse_omm(mixed_case)
        @test parse_omm(mixed_case; strict = false) isa OrbitMeanElementsMessage
    end

    @testset "Field Tag" begin
        mixed_case = replace(
            xml,
            "<ORIGINATOR>" => "<Originator>",
            "</ORIGINATOR>" => "</Originator>",
        )
        @test_throws ArgumentError parse_omm(mixed_case)
        @test parse_omm(mixed_case; strict = false) isa OrbitMeanElementsMessage
        @test only(parse_omms(mixed_case; strict = false)) isa OrbitMeanElementsMessage
        @test only(parse_odm(mixed_case; strict = false)) isa OrbitMeanElementsMessage
    end

    @testset "ID Attribute Value" begin
        mixed_case = replace(xml, "CCSDS_OMM_VERS" => "ccsds_omm_vers")
        @test_throws ArgumentError parse_omm(mixed_case)
        @test parse_omm(mixed_case; strict = false) isa OrbitMeanElementsMessage
    end
end
