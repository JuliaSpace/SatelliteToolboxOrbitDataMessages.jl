## Description #############################################################################
#
# Structural equality tests.
#
############################################################################################

@testset "Structural Equality" begin
    omm_1 = parse_omm(_fixture_omm_xml())
    omm_2 = parse_omm(_fixture_omm_xml())

    @test omm_1 == omm_2
    @test omm_1.header == omm_2.header
    @test omm_1.body == omm_2.body
    @test omm_1.body.segment == omm_2.body.segment
    @test omm_1.body.segment.metadata == omm_2.body.segment.metadata
    @test omm_1.body.segment.data == omm_2.body.segment.data

    covariance_1 = parse_omm(
        _minimal_omm_xml(; covariance_matrix_xml = _COV_XML)
    ).body.segment.data.covariance_matrix
    covariance_2 = parse_omm(
        _minimal_omm_xml(; covariance_matrix_xml = _COV_XML)
    ).body.segment.data.covariance_matrix
    @test covariance_1 == covariance_2

    different_covariance_xml = replace(_COV_XML, "<CX_X>1.0</CX_X>" => "<CX_X>2.0</CX_X>")
    different_covariance = parse_omm(
        _minimal_omm_xml(; covariance_matrix_xml = different_covariance_xml)
    ).body.segment.data.covariance_matrix
    @test covariance_1 != different_covariance

    @test omm_1 != OrbitMeanElementsMessage(omm_2; originator = "OTHER")
    @test omm_1 != OrbitMeanElementsMessage(omm_2; object_name = "OTHER")
    @test omm_1 != OrbitMeanElementsMessage(omm_2; eccentricity = 0.5)
    @test omm_1 != OrbitMeanElementsMessage(omm_2; data_comments = ["OTHER"])
    @test omm_1 != OrbitMeanElementsMessage(
        omm_2;
        user_defined_parameters = ["OTHER" => "VALUE"]
    )

    nan_omm = OrbitMeanElementsMessage(omm_1; eccentricity = NaN)
    @test nan_omm != nan_omm
end

@testset "Hash Consistency" begin
    omm_1 = parse_omm(_fixture_omm_xml())
    omm_2 = parse_omm(_fixture_omm_xml())

    # `==` must imply equal hashes so that the types work in `Dict`s and `Set`s.
    @test hash(omm_1) == hash(omm_2)
    @test hash(omm_1.header) == hash(omm_2.header)
    @test hash(omm_1.body) == hash(omm_2.body)
    @test omm_1 in Set([omm_2])
    @test length(unique([omm_1, omm_2])) == 1

    different_omm = OrbitMeanElementsMessage(omm_2; originator = "OTHER")
    @test hash(omm_1) != hash(different_omm)
end
