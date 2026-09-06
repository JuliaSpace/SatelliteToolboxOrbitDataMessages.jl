## Description #############################################################################
#
# XML tag case-insensitivity tests.
#
############################################################################################

@testset "Tag Case-Insensitivity" verbose = true begin
    xml = _minimal_omm_xml()
    omm = parse_omm(xml)

    @testset "Structural Tag" begin
        mixed_case = replace(xml, "<header>" => "<Header>", "</header>" => "</Header>")
        @test parse_omm(mixed_case) == omm
    end

    @testset "Field Tag" begin
        mixed_case = replace(
            xml, "<ORIGINATOR>" => "<Originator>", "</ORIGINATOR>" => "</Originator>"
        )
        @test parse_omm(mixed_case) == omm
        @test only(parse_omms(mixed_case)) == omm
        @test only(parse_odm(mixed_case)) == omm
    end

    @testset "ID Attribute Value" begin
        mixed_case = replace(xml, "CCSDS_OMM_VERS" => "ccsds_omm_vers")
        @test parse_omm(mixed_case) == omm
    end

    @testset "Root and Section Tags" begin
        mixed_case = replace(
            _ndm_xml(_omm_element_from_fixture()),
            "<ndm" => "<NDM",
            "</ndm>" => "</NDM>",
            "<omm" => "<OMM",
            "</omm>" => "</OMM>",
            "<meanElements>" => "<MEANELEMENTS>",
            "</meanElements>" => "</MEANELEMENTS>",
        )
        @test only(parse_omms(mixed_case)) == parse_omm(_fixture_omm_xml())
    end

    @testset "Non-ASCII Tags Are Compared Exactly" begin
        mixed_case = replace(
            xml, "<ORIGINATOR>" => "<ORIGINATÖR>", "</ORIGINATOR>" => "</ORIGINATÖR>"
        )
        @test_throws OdmParseError parse_omm(mixed_case)
    end
end
