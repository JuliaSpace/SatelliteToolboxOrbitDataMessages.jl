## Description #############################################################################
#
# Tests of the section fields forwarded as properties of the message.
#
############################################################################################

@testset "Forwarded Properties" begin
    omm = parse_omm(_fixture_omm_xml())

    # Every section field but the comments must be available as a property of the message.
    for (section, T) in ((:header, OmmHeader), (:metadata, OmmMetadata), (:data, OmmData))
        for field in fieldnames(T)
            field === :comments && continue
            @test hasproperty(omm, field)
            @test getproperty(omm, field) === getfield(getfield(omm, section), field)
        end
    end

    # The structure fields are still available.
    @test omm.version === getfield(omm, :version)
    @test omm.header === getfield(omm, :header)
    @test omm.metadata === getfield(omm, :metadata)
    @test omm.data === getfield(omm, :data)

    # Spot-check some properties against the fixture values. The accesses are wrapped in
    # functions so that the property name is a literal, which must be inferred.
    object_name(omm) = omm.object_name
    object_id(omm)   = omm.object_id
    originator(omm)  = omm.originator
    epoch(omm)       = omm.epoch

    @test (@inferred object_name(omm)) == "AMAZONIA 1"
    @test (@inferred object_id(omm)) == "2021-015A"
    @test (@inferred originator(omm)) == "18 SPCS"
    @test (@inferred epoch(omm)) == NanoDate("2025-12-30T18:12:04.533984")
    @test omm.mean_motion ≈ 14.40772474
    @test omm.eccentricity ≈ 0.0001124
    @test omm.norad_cat_id == 47699

    # The comments are ambiguous, so they are only reachable through the sections.
    @test !hasproperty(omm, :comments)
    @test_throws Exception omm.comments
    @test omm.header.comments == ["GENERATED VIA SPACE-TRACK.ORG API"]
    @test omm.mean_elements_comments == omm.data.mean_elements_comments

    # `propertynames` lists the structure fields followed by the forwarded ones.
    names = propertynames(omm)
    @test names[1:4] == (:version, :header, :metadata, :data)
    @test :epoch in names
    @test :comments ∉ names
    @test length(names) ==
        4 +
        count(!=(:comments), fieldnames(OmmHeader)) +
        count(!=(:comments), fieldnames(OmmMetadata)) +
        count(!=(:comments), fieldnames(OmmData))
end
