## Description #############################################################################
#
# User-defined parameters edge cases.
#
############################################################################################

@testset "User-Defined Parameters" verbose = true begin
    # == No userDefinedParameters Section -> nothing =======================================

    @testset "No Section" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)
        @test !isnothing(omm)
        @test isnothing(omm.body.segment.data.user_defined_parameters)
    end

    # == Missing Parameter Attribute =======================================================

    @testset "Missing Parameter Attribute" begin
        ud_xml = """
        <userDefinedParameters><USER_DEFINED>my_value</USER_DEFINED></userDefinedParameters>
        """
        xml = _minimal_omm_xml(user_defined_xml=ud_xml)
        @test_throws ArgumentError parse_omm(xml)
    end

    # == Duplicate Keys Preserved ==========================================================

    @testset "Duplicate Keys" begin
        ud_xml = """
        <userDefinedParameters>
          <USER_DEFINED parameter="KEY">val1</USER_DEFINED>
          <USER_DEFINED parameter="KEY">val2</USER_DEFINED>
        </userDefinedParameters>
        """
        xml = _minimal_omm_xml(user_defined_xml=ud_xml)
        omm = parse_omm(xml)

        @test !isnothing(omm)
        udp = omm.body.segment.data.user_defined_parameters
        @test !isnothing(udp)
        @test length(udp) == 2
        @test udp[1].first == "KEY"
        @test udp[1].second == "val1"
        @test udp[2].first == "KEY"
        @test udp[2].second == "val2"
    end

    @testset "Decoded Entities" begin
        ud_xml = """
        <userDefinedParameters>
          <USER_DEFINED parameter="A&amp;B">left &amp; right</USER_DEFINED>
        </userDefinedParameters>
        """
        omm = parse_omm(_minimal_omm_xml(; user_defined_xml = ud_xml))

        @test only(omm.body.segment.data.user_defined_parameters) ==
            ("A&B" => "left & right")
    end
end
