## Description #############################################################################
#
# Covariance matrix parsing and writing tests.
#
############################################################################################

@testset "Covariance Matrix" verbose = true begin
    @testset "Parse Covariance Matrix" begin
        xml = _minimal_omm_xml(; covariance_matrix_xml = _COV_XML)
        omm = parse_omm(xml)

        @test !isnothing(omm)

        cov = omm.data.covariance_matrix
        @test !isnothing(cov)
        @test cov.comments == ["This is a covariance matrix"]
        @test cov.cov_ref_frame == "ITRF"
        @test cov.cx_x == 1.0
        @test cov.cy_x == 2.0
        @test cov.cy_y == 3.0
        @test cov.cz_x == 4.0
        @test cov.cz_y == 5.0
        @test cov.cz_z == 6.0
        @test cov.cx_dot_x == 7.0
        @test cov.cx_dot_y == 8.0
        @test cov.cx_dot_z == 9.0
        @test cov.cx_dot_x_dot == 10.0
        @test cov.cy_dot_x == 11.0
        @test cov.cy_dot_y == 12.0
        @test cov.cy_dot_z == 13.0
        @test cov.cy_dot_x_dot == 14.0
        @test cov.cy_dot_y_dot == 15.0
        @test cov.cz_dot_x == 16.0
        @test cov.cz_dot_y == 17.0
        @test cov.cz_dot_z == 18.0
        @test cov.cz_dot_x_dot == 19.0
        @test cov.cz_dot_y_dot == 20.0
        @test cov.cz_dot_z_dot == 21.0
    end

    @testset "Parse Covariance Matrix Without Optional Fields" begin
        cov_xml = """
        <covarianceMatrix>
            <CX_X>1.0</CX_X>
            <CY_X>2.0</CY_X>
            <CY_Y>3.0</CY_Y>
            <CZ_X>4.0</CZ_X>
            <CZ_Y>5.0</CZ_Y>
            <CZ_Z>6.0</CZ_Z>
            <CX_DOT_X>7.0</CX_DOT_X>
            <CX_DOT_Y>8.0</CX_DOT_Y>
            <CX_DOT_Z>9.0</CX_DOT_Z>
            <CX_DOT_X_DOT>10.0</CX_DOT_X_DOT>
            <CY_DOT_X>11.0</CY_DOT_X>
            <CY_DOT_Y>12.0</CY_DOT_Y>
            <CY_DOT_Z>13.0</CY_DOT_Z>
            <CY_DOT_X_DOT>14.0</CY_DOT_X_DOT>
            <CY_DOT_Y_DOT>15.0</CY_DOT_Y_DOT>
            <CZ_DOT_X>16.0</CZ_DOT_X>
            <CZ_DOT_Y>17.0</CZ_DOT_Y>
            <CZ_DOT_Z>18.0</CZ_DOT_Z>
            <CZ_DOT_X_DOT>19.0</CZ_DOT_X_DOT>
            <CZ_DOT_Y_DOT>20.0</CZ_DOT_Y_DOT>
            <CZ_DOT_Z_DOT>21.0</CZ_DOT_Z_DOT>
        </covarianceMatrix>
        """
        xml = _minimal_omm_xml(; covariance_matrix_xml = cov_xml)
        omm = parse_omm(xml)

        @test !isnothing(omm)

        cov = omm.data.covariance_matrix
        @test !isnothing(cov)
        @test isempty(cov.comments)
        @test isnothing(cov.cov_ref_frame)
        @test cov.cx_x == 1.0
        @test cov.cz_dot_z_dot == 21.0
    end

    @testset "Missing Covariance Matrix Defaults to nothing" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test isnothing(omm.data.covariance_matrix)
    end

    @testset "Missing Required Element Throws" begin
        cov_xml = """
        <covarianceMatrix>
            <CX_X>1.0</CX_X>
            <CY_X>2.0</CY_X>
            <CY_Y>3.0</CY_Y>
            <CZ_X>4.0</CZ_X>
            <CZ_Y>5.0</CZ_Y>
            <CZ_Z>6.0</CZ_Z>
            <CX_DOT_X>7.0</CX_DOT_X>
            <CX_DOT_Y>8.0</CX_DOT_Y>
            <CX_DOT_Z>9.0</CX_DOT_Z>
            <CX_DOT_X_DOT>10.0</CX_DOT_X_DOT>
            <CY_DOT_X>11.0</CY_DOT_X>
            <CY_DOT_Y>12.0</CY_DOT_Y>
            <CY_DOT_Z>13.0</CY_DOT_Z>
            <CY_DOT_X_DOT>14.0</CY_DOT_X_DOT>
            <CY_DOT_Y_DOT>15.0</CY_DOT_Y_DOT>
            <CZ_DOT_X>16.0</CZ_DOT_X>
            <CZ_DOT_Y>17.0</CZ_DOT_Y>
            <CZ_DOT_Z>18.0</CZ_DOT_Z>
            <CZ_DOT_X_DOT>19.0</CZ_DOT_X_DOT>
            <CZ_DOT_Y_DOT>20.0</CZ_DOT_Y_DOT>
        </covarianceMatrix>
        """
        xml = _minimal_omm_xml(; covariance_matrix_xml = cov_xml)

        @test_throws OdmParseError parse_omm(xml)
    end

    @testset "Write Covariance Matrix Round-Trip" begin
        xml = _minimal_omm_xml(; covariance_matrix_xml = _COV_XML)
        omm = parse_omm(xml)

        buf = IOBuffer()
        write_omm(buf, omm)
        written_xml = String(take!(buf))

        omm_reparsed = parse_omm(written_xml)

        @test !isnothing(omm_reparsed)

        cov1 = omm.data.covariance_matrix
        cov2 = omm_reparsed.data.covariance_matrix

        @test !isnothing(cov2)
        @test cov1.comments == cov2.comments
        @test cov1.cov_ref_frame == cov2.cov_ref_frame
        @test cov1.cx_x == cov2.cx_x
        @test cov1.cy_x == cov2.cy_x
        @test cov1.cy_y == cov2.cy_y
        @test cov1.cz_x == cov2.cz_x
        @test cov1.cz_y == cov2.cz_y
        @test cov1.cz_z == cov2.cz_z
        @test cov1.cx_dot_x == cov2.cx_dot_x
        @test cov1.cx_dot_y == cov2.cx_dot_y
        @test cov1.cx_dot_z == cov2.cx_dot_z
        @test cov1.cx_dot_x_dot == cov2.cx_dot_x_dot
        @test cov1.cy_dot_x == cov2.cy_dot_x
        @test cov1.cy_dot_y == cov2.cy_dot_y
        @test cov1.cy_dot_z == cov2.cy_dot_z
        @test cov1.cy_dot_x_dot == cov2.cy_dot_x_dot
        @test cov1.cy_dot_y_dot == cov2.cy_dot_y_dot
        @test cov1.cz_dot_x == cov2.cz_dot_x
        @test cov1.cz_dot_y == cov2.cz_dot_y
        @test cov1.cz_dot_z == cov2.cz_dot_z
        @test cov1.cz_dot_x_dot == cov2.cz_dot_x_dot
        @test cov1.cz_dot_y_dot == cov2.cz_dot_y_dot
        @test cov1.cz_dot_z_dot == cov2.cz_dot_z_dot
    end

    @testset "Matrix Conversions" begin
        omm = parse_omm(_minimal_omm_xml(; covariance_matrix_xml = _COV_XML))
        cov = omm.data.covariance_matrix

        # The lower triangle holds the elements 1 to 21 in row-major order.
        expected = zeros(6, 6)
        k = 0
        for i in 1:6, j in 1:i
            k += 1
            expected[i, j] = expected[j, i] = k
        end

        @test Matrix(cov) == expected
        @test Matrix(cov) isa Matrix{Float64}
        @test SMatrix(cov) == expected
        @test SMatrix(cov) isa SMatrix{6, 6, Float64, 36}
        @test Matrix(cov)[4, 1] == cov.cx_dot_x
        @test Matrix(cov)[6, 5] == cov.cz_dot_y_dot

        # A section built from the matrix equals the parsed one.
        @test OmmCovarianceMatrix(
            expected; comments = cov.comments, cov_ref_frame = cov.cov_ref_frame
        ) == cov
        @test OmmCovarianceMatrix(SMatrix(cov)).cz_dot_z_dot == 21.0
        @test isempty(OmmCovarianceMatrix(expected).comments)
        @test isnothing(OmmCovarianceMatrix(expected).cov_ref_frame)

        # Only the lower triangle is read.
        asymmetric = copy(expected)
        asymmetric[1, 2] = 100.0
        @test OmmCovarianceMatrix(asymmetric) == OmmCovarianceMatrix(expected)

        @test_throws ArgumentError OmmCovarianceMatrix(zeros(3, 3))
    end

    @testset "Write Without Covariance Matrix" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)

        buf = IOBuffer()
        write_omm(buf, omm)
        written_xml = String(take!(buf))

        @test !occursin("covarianceMatrix", written_xml)
    end
end
