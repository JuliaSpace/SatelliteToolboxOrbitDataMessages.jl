## Description #############################################################################
#
# Parsing round-trip tests.
#
############################################################################################

@testset "Round-trip" verbose = true begin
    omm_file = read_omm(_FIXTURE_FILE)
    xml_str  = _fixture_omm_xml()

    # == parse_omm / parse_omms / parse_odm / read_omm agree ===============================

    @testset "All parsers agree" begin
        omm_parse_omm  = parse_omm(xml_str)
        omm_parse_omms = parse_omms(xml_str)
        vodm_parse_odm = parse_odm(xml_str)

        @test !isnothing(omm_parse_omm)
        @test !isnothing(omm_parse_omms)
        @test !isnothing(vodm_parse_odm)

        # parse_omms returns a vector with the single OMM.
        @test length(omm_parse_omms) == 1

        # parse_odm returns a single-element vector (after the standardization).
        @test length(vodm_parse_odm) == 1

        # Compare field-by-field (Julia does not auto-define == for structs with
        # non-bits fields like String).
        for omm in (first(omm_parse_omms), first(vodm_parse_odm), omm_file)
            @test omm.version                == omm_parse_omm.version
            @test omm.header.comments        ==  omm_parse_omm.header.comments
            @test omm.header.classification  === omm_parse_omm.header.classification
            @test omm.header.creation_date   ==  omm_parse_omm.header.creation_date
            @test omm.header.originator      ==  omm_parse_omm.header.originator
            @test omm.header.message_id      === omm_parse_omm.header.message_id
            @test omm.body.segment.metadata.object_name ==
                omm_parse_omm.body.segment.metadata.object_name
            @test omm.body.segment.data.epoch ==
                omm_parse_omm.body.segment.data.epoch
            @test omm.body.segment.data.mean_motion ≈
                omm_parse_omm.body.segment.data.mean_motion
        end
    end

    # == write_omm + re-parse ==============================================================

    @testset "write_omm round-trip" begin
        buf = IOBuffer()
        write_omm(buf, omm_file)
        written_xml = String(take!(buf))

        omm_reparsed = parse_omm(written_xml)

        @test !isnothing(omm_reparsed)
        @test omm_reparsed.header.comments == omm_file.header.comments
        @test omm_reparsed.header.creation_date == omm_file.header.creation_date
        @test omm_reparsed.header.originator == omm_file.header.originator
        @test omm_reparsed.body.segment.metadata.comments ==
            omm_file.body.segment.metadata.comments
        @test omm_reparsed.body.segment.metadata.object_name ==
            omm_file.body.segment.metadata.object_name

        # Compare the data fields (skip user_defined_parameters ordering for now).
        d1 = omm_reparsed.body.segment.data
        d2 = omm_file.body.segment.data

        @test d1.epoch             == d2.epoch
        @test d1.semi_major_axis   === d2.semi_major_axis
        @test d1.mean_motion       ≈   d2.mean_motion
        @test d1.eccentricity      ≈   d2.eccentricity
        @test d1.inclination       ≈   d2.inclination
        @test d1.raan              ≈   d2.raan
        @test d1.arg_of_pericenter ≈   d2.arg_of_pericenter
        @test d1.mean_anomaly      ≈   d2.mean_anomaly
        @test d1.GM                === d2.GM
        @test d1.ephemeris_type         == d2.ephemeris_type
        @test d1.classification_type    == d2.classification_type
        @test d1.norad_cat_id           == d2.norad_cat_id
        @test d1.element_set_number     == d2.element_set_number
        @test d1.rev_at_epoch           == d2.rev_at_epoch
        @test d1.bstar                  ≈   d2.bstar
        @test d1.mean_motion_dot        ≈   d2.mean_motion_dot
        @test d1.mean_motion_ddot       ≈   d2.mean_motion_ddot

        # User-defined parameters: compare as Dict (ordering may differ).
        ud1 = isnothing(d1.user_defined_parameters) ? Dict() :
            Dict(d1.user_defined_parameters)
        ud2 = isnothing(d2.user_defined_parameters) ? Dict() :
            Dict(d2.user_defined_parameters)
        @test ud1 == ud2
    end

    # == write_odm (vector form) + re-parse ================================================

    @testset "write_odm vector round-trip" begin
        buf = IOBuffer()
        write_odm(buf, [omm_file])
        written_xml = String(take!(buf))

        vodm_reparsed = parse_odm(written_xml)

        @test !isnothing(vodm_reparsed)
        @test length(vodm_reparsed) == 1
        @test first(vodm_reparsed) isa OrbitMeanElementsMessage
        @test first(vodm_reparsed).header.creation_date == omm_file.header.creation_date
        @test first(vodm_reparsed).header.originator   == omm_file.header.originator
        @test first(vodm_reparsed).body.segment.metadata.object_name ==
            omm_file.body.segment.metadata.object_name
    end
end
