## Description #############################################################################
#
# Tests for OMM version-specific schema validation.
#
############################################################################################

@testset "OMM Version 2.0 Schema" verbose = true begin
    tle_params_2_0 = """
    <tleParameters>
        <BSTAR>0.0001</BSTAR>
        <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
        <MEAN_MOTION_DDOT>0.0</MEAN_MOTION_DDOT>
    </tleParameters>
    """

    # == Valid Version 2.0 Message =========================================================

    @testset "Valid Version 2.0 Message" begin
        omm = parse_omm(
            _minimal_omm_xml(; omm_version = "2.0", tle_params_xml = tle_params_2_0)
        )

        @test !isnothing(omm)
        @test omm.version == v"2.0"
        @test omm.body.segment.data.bstar == 0.0001
        @test omm.body.segment.data.mean_motion_ddot == 0.0
    end

    # == Version 3.0 Header Fields Rejected in Strict Mode =================================

    @testset "Version 3.0 Header Fields Rejected in Strict Mode" begin
        for kwargs in ((; classification = "U"), (; message_id = "MSG-001"))
            xml = _minimal_omm_xml(; omm_version = "2.0", kwargs...)
            @test_throws ArgumentError parse_omm(xml)

            # Non-strict mode keeps the current leniency.
            omm = parse_omm(xml; strict = false)
            @test !isnothing(omm)
        end
    end

    # == Version 3.0 TLE Parameters Rejected in Strict Mode ================================

    @testset "Version 3.0 TLE Parameters Rejected in Strict Mode" begin
        for tle_params_xml in (
            """
            <tleParameters>
                <BTERM>0.0001</BTERM>
                <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
                <MEAN_MOTION_DDOT>0.0</MEAN_MOTION_DDOT>
            </tleParameters>
            """,
            """
            <tleParameters>
                <BSTAR>0.0001</BSTAR>
                <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
                <AGOM>0.01</AGOM>
            </tleParameters>
            """,
        )
            xml = _minimal_omm_xml(; omm_version = "2.0", tle_params_xml = tle_params_xml)
            @test_throws ArgumentError parse_omm(xml)

            # Non-strict mode keeps the current leniency.
            omm = parse_omm(xml; strict = false)
            @test !isnothing(omm)

            # The same section is valid in a version 3.0 message.
            omm = parse_omm(_minimal_omm_xml(; tle_params_xml = tle_params_xml))
            @test !isnothing(omm)
        end
    end

    # == Version 2.0 Required TLE Parameters ===============================================

    @testset "Version 2.0 Required TLE Parameters" begin
        for tle_params_xml in (
            """
            <tleParameters>
                <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
                <MEAN_MOTION_DDOT>0.0</MEAN_MOTION_DDOT>
            </tleParameters>
            """,
            """
            <tleParameters>
                <BSTAR>0.0001</BSTAR>
                <MEAN_MOTION_DOT>0.0</MEAN_MOTION_DOT>
            </tleParameters>
            """,
        )
            xml = _minimal_omm_xml(; omm_version = "2.0", tle_params_xml = tle_params_xml)
            @test_throws ArgumentError parse_omm(xml)
        end
    end
end
