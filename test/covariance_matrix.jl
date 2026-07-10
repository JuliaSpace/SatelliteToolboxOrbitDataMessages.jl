## Description #############################################################################
#
# Covariance matrix parsing and writing tests.
#
############################################################################################

# Sample covariance matrix XML with all 21 elements and optional fields.
const _COV_XML = """
<covarianceMatrix>
    <COMMENT>This is a covariance matrix</COMMENT>
    <COV_REF_FRAME>ITRF</COV_REF_FRAME>
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

@testset "Covariance matrix" verbose = true begin
    @testset "Parse covariance matrix" begin
        xml = _minimal_omm_xml(; covariance_matrix_xml = _COV_XML)
        omm = parse_omm(xml)

        @test !isnothing(omm)

        cov = omm.body.segment.data.covariance_matrix
        @test !isnothing(cov)
        @test cov.comments == ["This is a covariance matrix"]
        @test cov.cov_ref_frame == "ITRF"
        @test cov.cx_x           == 1.0
        @test cov.cy_x           == 2.0
        @test cov.cy_y           == 3.0
        @test cov.cz_x           == 4.0
        @test cov.cz_y           == 5.0
        @test cov.cz_z           == 6.0
        @test cov.cx_dot_x       == 7.0
        @test cov.cx_dot_y       == 8.0
        @test cov.cx_dot_z       == 9.0
        @test cov.cx_dot_x_dot   == 10.0
        @test cov.cy_dot_x       == 11.0
        @test cov.cy_dot_y       == 12.0
        @test cov.cy_dot_z       == 13.0
        @test cov.cy_dot_x_dot   == 14.0
        @test cov.cy_dot_y_dot   == 15.0
        @test cov.cz_dot_x       == 16.0
        @test cov.cz_dot_y       == 17.0
        @test cov.cz_dot_z       == 18.0
        @test cov.cz_dot_x_dot   == 19.0
        @test cov.cz_dot_y_dot   == 20.0
        @test cov.cz_dot_z_dot   == 21.0
    end

    @testset "Parse covariance matrix without optional fields" begin
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

        cov = omm.body.segment.data.covariance_matrix
        @test !isnothing(cov)
        @test isempty(cov.comments)
        @test isnothing(cov.cov_ref_frame)
        @test cov.cx_x == 1.0
        @test cov.cz_dot_z_dot == 21.0
    end

    @testset "Missing covariance matrix defaults to nothing" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)

        @test !isnothing(omm)
        @test isnothing(omm.body.segment.data.covariance_matrix)
    end

    @testset "Missing required element throws" begin
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

        @test_throws ArgumentError parse_omm(xml)
    end

    @testset "Write covariance matrix round-trip" begin
        xml = _minimal_omm_xml(; covariance_matrix_xml = _COV_XML)
        omm = parse_omm(xml)

        buf = IOBuffer()
        write_omm(buf, omm)
        written_xml = String(take!(buf))

        omm_reparsed = parse_omm(written_xml)

        @test !isnothing(omm_reparsed)

        cov1 = omm.body.segment.data.covariance_matrix
        cov2 = omm_reparsed.body.segment.data.covariance_matrix

        @test !isnothing(cov2)
        @test cov1.comments      == cov2.comments
        @test cov1.cov_ref_frame == cov2.cov_ref_frame
        @test cov1.cx_x           == cov2.cx_x
        @test cov1.cy_x           == cov2.cy_x
        @test cov1.cy_y           == cov2.cy_y
        @test cov1.cz_x           == cov2.cz_x
        @test cov1.cz_y           == cov2.cz_y
        @test cov1.cz_z           == cov2.cz_z
        @test cov1.cx_dot_x       == cov2.cx_dot_x
        @test cov1.cx_dot_y       == cov2.cx_dot_y
        @test cov1.cx_dot_z       == cov2.cx_dot_z
        @test cov1.cx_dot_x_dot   == cov2.cx_dot_x_dot
        @test cov1.cy_dot_x       == cov2.cy_dot_x
        @test cov1.cy_dot_y       == cov2.cy_dot_y
        @test cov1.cy_dot_z       == cov2.cy_dot_z
        @test cov1.cy_dot_x_dot   == cov2.cy_dot_x_dot
        @test cov1.cy_dot_y_dot   == cov2.cy_dot_y_dot
        @test cov1.cz_dot_x       == cov2.cz_dot_x
        @test cov1.cz_dot_y       == cov2.cz_dot_y
        @test cov1.cz_dot_z       == cov2.cz_dot_z
        @test cov1.cz_dot_x_dot   == cov2.cz_dot_x_dot
        @test cov1.cz_dot_y_dot   == cov2.cz_dot_y_dot
        @test cov1.cz_dot_z_dot   == cov2.cz_dot_z_dot
    end

    @testset "Write without covariance matrix" begin
        xml = _minimal_omm_xml()
        omm = parse_omm(xml)

        buf = IOBuffer()
        write_omm(buf, omm)
        written_xml = String(take!(buf))

        @test !occursin("covarianceMatrix", written_xml)
    end
end
